"""日本麻将的算点和积分规则"""

from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import List, Optional

from game_data.io import Deserializable


NAGASHI_MANGAN_AS_DRAW = True
"""根据天凤/雀魂规则，荒牌流局视为流局（亲家听牌则连庄）"""


class Wind(Enum):
    """风"""

    East = 0
    South = 1
    West = 2
    North = 3

    @property
    def next(self) -> Wind:
        return Wind((self.value + 1) % 4)


class RoundEnding(Enum):
    """一局游戏结束的方式"""

    NULL = auto()
    """暂未填充"""

    Ron = auto()
    """荣和"""

    Tsumo = auto()
    """自摸"""

    ExhaustiveDraw = auto()
    """荒牌流局（不包括流局满贯）"""

    AbortiveDraw = auto()
    """流局（除荒牌流局和流局满贯之外的流局，均不计分）"""

    NagashiMangan = auto()
    """流局满贯"""

    @property
    def is_win(self):
        """有人和牌（亲家未和则下庄，且收走立直棒），否则视为流局（亲家听牌则连庄，且不收立直棒）"""
        assert self != RoundEnding.NULL
        if self == RoundEnding.NagashiMangan:
            return not NAGASHI_MANGAN_AS_DRAW
        return self in [RoundEnding.Ron, RoundEnding.Tsumo]


@dataclass
class RoundWin(Deserializable):
    """一个玩家的和牌（一局可能包含多个）

    流局满贯时计为 4 番 40 符
    """

    winner: int
    """和牌玩家的座次（0-3）"""

    han: int
    """番数"""

    fu: int
    """符数"""

    loser: Optional[int] = field(default=None)
    """放铳玩家的座次（0-3）"""

    yakuman: int = field(default=0)
    """役满倍数（包括累计役满）"""

    def __post_init__(self):
        # 累计役满计入役满倍数
        if self.han >= 13:
            self.yakuman = 1

    @classmethod
    def nagashi_mangan(cls, winner: int) -> RoundWin:
        """流局满贯所用的计分对象"""
        return cls(winner, 4, 40)

    @property
    def base_point(self) -> int:
        """计算基本分数（子家自摸时的子家分数）"""
        base = 4 * self.fu * (1 << self.han)
        base = (base + 99) // 100 * 100
        if base < 2000:
            return base
        if self.han >= 13:
            return 8000
        elif self.han >= 11:
            return 6000
        elif self.han >= 8:
            return 4000
        elif self.han >= 6:
            return 3000
        else:
            return 2000


@dataclass
class RoundResult(Deserializable):
    """一局游戏的结果"""

    dealer: int
    """亲家的座次（0-3）"""

    prevailing_wind: Wind
    """场风"""

    honba: int
    """本场数，从 0 开始计"""

    ending: RoundEnding
    """结果的类型"""

    wins: List[RoundWin] = field(default_factory=list)
    """和牌情况（可能包括 0-3 个），流局满贯时应为 4 番 40 符"""

    riichi: List[bool] = field(default_factory=lambda: [False for _ in range(4)])
    """立直状态"""

    accumulated_riichi: int = field(default=0)
    """累计立直棒的数量（此局开始前，单位为 1）"""

    tenpai: Optional[List[bool]] = field(default=None)
    """听牌状态（仅对荒牌流局有意义）"""

    @property
    def honba_points(self) -> int:
        """本场的额外点数"""
        return self.honba * 100

    def _compute_points_ron(self) -> List[int]:
        """荣和情况下计算得点"""

        player_points = [0 - 1000 * self.riichi[i] for i in range(4)]
        riichi_points = 1000 * sum(self.riichi) + self.accumulated_riichi

        for win in self.wins:
            assert win.loser is not None

            if win.yakuman is not None:
                # 役满荣和

                # 亲/子家计算基本点数
                if win.winner == self.dealer:
                    points = 48000 * win.yakuman
                else:
                    points = 32000 * win.yakuman

            else:
                # 荣和（非役满）
                if win.winner == self.dealer:
                    points = 6 * win.base_point
                else:
                    points = 6 * win.base_point

            points += 3 * self.honba_points
            player_points[win.winner] += points + riichi_points
            player_points[win.loser] -= points

        return player_points

    def _compute_points_tsumo(self) -> List[int]:
        """自摸情况下计算得点（流局满贯也会用到）"""

        (win,) = self.wins
        player_points = [0 - 1000 * self.riichi[i] for i in range(4)]
        riichi_points = 1000 * sum(self.riichi) + self.accumulated_riichi
        base = win.base_point

        if win.winner == self.dealer:
            # 亲家自摸
            player_points = [-2 * base - self.honba_points for _ in range(4)]
            player_points[win.winner] = 6 * base + 3 * self.honba_points + riichi_points
        else:
            # 子家自摸
            player_points = [-1 * base - self.honba_points for _ in range(4)]
            player_points[win.winner] = 4 * base + self.honba_points + riichi_points
            player_points[self.dealer] = -2 * base - self.honba_points

        return player_points

    def _compute_points_exhaustive_draw(self) -> List[int]:
        """荒牌流局情况下计算得点"""
        assert self.tenpai is not None and len(self.tenpai) == 4
        tenpai_player_count = sum(self.tenpai)
        player_points = [0 - 1000 * self.riichi[i] for i in range(4)]

        if tenpai_player_count == 0 or tenpai_player_count == 4:
            return player_points
        elif tenpai_player_count == 1:
            return [
                p - 1000 + 4000 * self.tenpai[i] for i, p in enumerate(player_points)
            ]
        elif tenpai_player_count == 2:
            return [
                p - 1000 + 2000 * self.tenpai[i] for i, p in enumerate(player_points)
            ]
        elif tenpai_player_count == 3:
            return [
                p - 3000 + 4000 * self.tenpai[i] for i, p in enumerate(player_points)
            ]
        else:
            raise Exception("Impossible")

    def _compute_points_nagashi_mangan(self) -> List[int]:
        """流局满贯情况下计算得点"""

        if NAGASHI_MANGAN_AS_DRAW:
            # 算作流局（不计听牌惩罚）

            winner = self.wins[0].winner
            if winner == self.dealer:
                player_points = [-4000 - 1000 * self.riichi[i] for i in range(4)]
                player_points[winner] += 16000
            else:
                player_points = [-2000 - 1000 * self.riichi[i] for i in range(4)]
                player_points[winner] += 10000
                player_points[self.dealer] -= 2000
            return player_points

        else:
            # 算作和牌
            return self._compute_points_tsumo()

    def compute_points(self) -> List[int]:
        """计算一局游戏中每人得点。返回包含 4 个 int，按照座次排序（与亲家位置无关）"""

        if self.ending == RoundEnding.Ron:
            return self._compute_points_ron()
        elif self.ending == RoundEnding.Tsumo:
            return self._compute_points_tsumo()
        elif self.ending == RoundEnding.ExhaustiveDraw:
            return self._compute_points_exhaustive_draw()
        elif self.ending == RoundEnding.AbortiveDraw:
            return [0 - 1000 * self.riichi[i] for i in range(4)]
        elif self.ending == RoundEnding.NagashiMangan:
            return self._compute_points_nagashi_mangan()
        else:
            raise Exception("Unimplemented RoundEnding", self.ending)

    def _renchan(self) -> bool:
        """判断此局游戏后是否连庄（不检查游戏是否已经结束）"""
        if self.ending == RoundEnding.Ron:
            return any(win.winner == self.dealer for win in self.wins)
        elif self.ending == RoundEnding.Tsumo:
            return self.wins[0].winner == self.dealer
        elif self.ending == RoundEnding.ExhaustiveDraw:
            assert self.tenpai is not None
            return self.tenpai[self.dealer]
        elif self.ending == RoundEnding.AbortiveDraw:
            return True
        elif self.ending == RoundEnding.NagashiMangan:
            return self.wins[0].winner == self.dealer
        else:
            raise Exception("Unimplemented RoundEnding", self.ending)

    def create_next(self) -> RoundResult:
        """自动生成下一局的场面信息（不检查游戏是否已经结束）"""

        if self.ending.is_win:
            accumulated_riichi = 0
        else:
            accumulated_riichi = self.accumulated_riichi + sum(self.riichi)

        if self._renchan():
            # 连庄
            return RoundResult(
                dealer=self.dealer,
                prevailing_wind=self.prevailing_wind,
                honba=self.honba + 1,
                ending=RoundEnding.NULL,
                accumulated_riichi=accumulated_riichi,
            )
        else:
            # 判断是否需要进下一个风场
            if self.dealer == 3:
                dealer = 0
                wind = self.prevailing_wind.next
            else:
                dealer = self.dealer + 1
                wind = self.prevailing_wind
            # 判断是否增加本场数
            if self.ending.is_win:
                honba = 0
            else:
                honba = self.honba + 1

            return RoundResult(
                dealer=dealer,
                prevailing_wind=wind,
                honba=honba,
                ending=RoundEnding.NULL,
                accumulated_riichi=accumulated_riichi,
            )
