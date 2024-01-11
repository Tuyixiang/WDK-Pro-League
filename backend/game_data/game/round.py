"""日本麻将的算点和积分规则"""

from __future__ import annotations

import sys
from dataclasses import dataclass, field
from enum import auto, IntEnum, StrEnum
from typing import List, Optional, Tuple

from .names import YAKU_NAMES
from game_data.io import Deserializable
from .tenhou import RoundFullInfo, RoundSimulationFailure

NAGASHI_MANGAN_AS_DRAW = True
"""根据天凤/雀魂规则，荒牌流局视为流局（亲家听牌则连庄）"""


class Wind(IntEnum):
    """风"""

    East = 0
    South = 1
    West = 2
    North = 3

    @property
    def next(self) -> Wind:
        return Wind((self.value + 1) % 4)


class RoundEnding(StrEnum):
    """一局游戏结束的方式"""

    NULL = "NULL"

    Ron = "和"

    Tsumo = "自摸"

    ExhaustiveDraw = "荒牌流局"

    SuufonRenda = "四风连打"

    KyuushuKyuuhai = "九种九牌"

    SuuchaRiichi = "四家立直"

    Suukaikan = "四开杠"

    Sanchahou = "三家和"

    NagashiMangan = "流局满贯"

    @property
    def is_abortive_draw(self):
        """流局（除荒牌流局和流局满贯之外的流局，均不计分）"""
        return self in [
            RoundEnding.SuufonRenda,
            RoundEnding.KyuushuKyuuhai,
            RoundEnding.SuuchaRiichi,
            RoundEnding.Suukaikan,
            RoundEnding.Sanchahou,
        ]

    @property
    def is_win(self):
        """有人和牌（亲家未和则下庄，且收走立直棒），否则视为流局（亲家听牌则连庄，且不收立直棒）"""
        assert self != RoundEnding.NULL
        if self == RoundEnding.NagashiMangan:
            return not NAGASHI_MANGAN_AS_DRAW
        return self in [RoundEnding.Ron, RoundEnding.Tsumo]

    @staticmethod
    def parse_tenhou(state: str) -> RoundEnding:
        """解析天凤的信息，但会将自摸也归于和"""
        if state == "和了":
            return RoundEnding.Ron
        elif state in ["流局", "Ryuukyoku"]:
            return RoundEnding.ExhaustiveDraw
        elif state in ["四風連打", "Suufon Renda"]:
            return RoundEnding.SuufonRenda
        elif state in ["九種九牌", "Kyuushu Kyuuhai"]:
            return RoundEnding.KyuushuKyuuhai
        elif state in ["四家立直", "Suucha Riichi"]:
            return RoundEnding.SuuchaRiichi
        elif state in ["四開槓", "Suukaikan"]:
            return RoundEnding.Suukaikan
        elif state in ["三家和", "Sanchahou"]:
            return RoundEnding.Sanchahou
        elif state in ["流し満貫", "Nagashi Mangan"]:
            return RoundEnding.NagashiMangan
        else:
            return RoundEnding.NULL


@dataclass
class RoundWin(Deserializable):
    """一个玩家的和牌（一局可能包含多个）

    流局满贯时计为 4 番 40 符
    """

    winner: int
    """和牌玩家的座次（0-3）"""

    loser: int
    """放铳玩家的座次（0-3），自摸则为 winner"""

    han: int
    """番数"""

    fu: int
    """符数"""

    yakuman: int = field(default=0)
    """役满倍数（包括累计役满）"""

    yaku: List[Tuple[str, int, int]] = field(default_factory=list)
    """役种（名称，番数，役满倍数）"""

    hand: Optional[Tuple[List[str], List[List[str]], str]] = field(default=None)
    """赢家的牌（暗牌、明牌、和牌）"""

    def __post_init__(self):
        # 累计役满计入役满倍数
        if self.han >= 13:
            self.yakuman = 1

    @classmethod
    def nagashi_mangan(cls, winner: int) -> RoundWin:
        """流局满贯所用的计分对象"""
        return cls(winner, winner, 4, 40)

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
class BaseRound(Deserializable):
    """一局游戏的结果（无论采用何种方式录入的共同接口）"""

    ending: RoundEnding

    prevailing_wind: Wind
    """场风"""

    dealer: int
    """亲家的座次（0-3）"""

    honba: int
    """本场数，从 0 开始计"""

    kyoutaku: int
    """供托数，每个立直棒计作 1"""

    initial_points: List[int] = field(default_factory=lambda: [25000] * 4)
    """一局开始时各家的点数"""

    result_points: List[List[int]] = field(default_factory=list)
    """本局游戏各家的点数变化（如果有多个荣和，则分别记录）
    
    九种九牌等中止牌局，将记录 [[0, 0, 0, 0]]。故任何情况下至少有一项"""

    final_hands: Optional[
        List[Tuple[List[str], List[List[str]], Optional[str]]]
    ] = field(default=None)
    """结束时每家的牌"""


@dataclass
class TenhouRound(BaseRound):
    """一局游戏的结果（通过天凤 JSON 录入）"""

    wins: List[RoundWin] = field(default_factory=list)
    """和牌情况（可能包括 0-3 个），流局满贯时应为 4 番 40 符"""

    riichi_status: Optional[List[bool]] = field(default=None)
    """立直状态"""

    full_info: Optional[RoundFullInfo] = field(default=None)

    @classmethod
    def from_json(cls, obj: list) -> TenhouRound:
        """从 JSON 数据中读取"""
        wind = Wind(obj[0][0] // 4)
        dealer = obj[0][0] % 4
        honba = obj[0][1]
        kyoutaku = obj[0][2]
        initial_points = obj[1]

        state = obj[-1][0]
        result_points = []
        wins = []

        ending = RoundEnding.parse_tenhou(state)
        if ending == RoundEnding.Ron:
            # 为每个和牌提取番数和符数
            for i in range(1, len(obj[-1]), 2):
                result_points.append(obj[-1][i])
                winner, loser, _, win_description, *yaku_list = obj[-1][i + 1]
                if winner == loser:
                    ending = RoundEnding.Tsumo
                yaku = []
                yakuman = 0
                han = 0
                for s in yaku_list:
                    # s 样例："Pinfu(1飜)", "Ura Dora(0飜)", "Four Concealed Triplets(役満)"
                    yaku_name, yaku_size = s.split(")")[0].split("(")
                    if "飜" in yaku_size:
                        yaku_han = int(yaku_size.split("飜")[0])
                        if yaku_han != 0:
                            han += yaku_han
                            yaku.append(
                                (YAKU_NAMES.get(yaku_name, yaku_name), yaku_han, 0)
                            )
                    elif "役満" in yaku_size:
                        yakuman_size = 2 if "倍" in yaku_size else 1
                        yakuman += yakuman_size
                        yaku.append(
                            (YAKU_NAMES.get(yaku_name, yaku_name), 0, yakuman_size)
                        )
                if "符" in win_description:
                    fu = int(win_description.split("符")[0])
                else:
                    fu = 40
                wins.append(
                    RoundWin(
                        winner=winner,
                        loser=loser,
                        han=han,
                        fu=fu,
                        yaku=yaku,
                        yakuman=yakuman,
                    )
                )
        elif ending == RoundEnding.ExhaustiveDraw:
            result_points.append(obj[-1][1])
        elif ending.is_abortive_draw:
            result_points.append([0, 0, 0, 0])
        else:
            print(f"未实现的结局：{state}")

        try:
            full_info = RoundFullInfo.from_json(obj)
            final_hands = [
                (*player.status, full_info.agari)
                for player in full_info.player_final_status
            ]
            riichi_status = full_info.riichi_status
        except (AssertionError, RoundSimulationFailure) as e:
            print(f"未能加载牌局 {e}", file=sys.stderr)
            final_hands = None
            riichi_status = None
            full_info = None
        return TenhouRound(
            ending=ending,
            prevailing_wind=wind,
            dealer=dealer,
            honba=honba,
            kyoutaku=kyoutaku,
            initial_points=initial_points,
            result_points=result_points,
            final_hands=final_hands,
            riichi_status=riichi_status,
            wins=wins,
            full_info=full_info,
        )


# TODO 尚未完成
@dataclass
class RoundResult(Deserializable):
    """一局游戏的结果（用于手动记录）"""

    dealer: int
    """亲家的座次（0-3）"""

    prevailing_wind: Wind
    """场风"""

    honba: int
    """本场数，从 0 开始计"""

    ending: RoundEnding = field(default=RoundEnding.NULL)
    """结果的类型"""

    wins: List[RoundWin] = field(default_factory=list)
    """和牌情况（可能包括 0-3 个），流局满贯时应为 4 番 40 符"""

    riichi: List[bool] = field(default_factory=lambda: [False for _ in range(4)])
    """立直状态"""

    accumulated_riichi: int = field(default=0)
    """累计立直棒的数量（此局开始前，单位为 1）"""

    tenpai: Optional[List[bool]] = field(default=None)
    """听牌状态（仅对荒牌流局有意义）"""

    initial_points: List[int] = field(default_factory=lambda: [25000] * 4)
    """一局开始时各家的点数"""

    result_points: List[int] = field(init=False, repr=False)
    """本局游戏各家的点数变化，缓存变量"""

    after_points: List[int] = field(init=False, repr=False)
    """一局结束时各家的点数，缓存变量"""

    @property
    def honba_points(self) -> int:
        """本场的额外点数"""
        return self.honba * 100

    def _compute_points_ron(self) -> List[int]:
        """荣和情况下计算得点"""

        player_points = [0 - 1000 * self.riichi[i] for i in range(4)]
        riichi_points = 1000 * sum(self.riichi) + self.accumulated_riichi

        for win in self.wins:
            assert win.loser != win.winner

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
            self.accumulated_riichi = 0
            riichi_points = 0

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

    def update(self):
        """计算所有临时变量"""
        self.result_points = self.compute_points()
        self.after_points = [
            a + b for a, b in zip(self.initial_points, self.result_points)
        ]

    def compute_points(self) -> List[int]:
        """计算一局游戏中每人得点。返回包含 4 个 int，按照座次排序（与亲家位置无关）"""

        if self.ending == RoundEnding.NULL:
            return [0] * 4
        elif self.ending == RoundEnding.Ron:
            return self._compute_points_ron()
        elif self.ending == RoundEnding.Tsumo:
            return self._compute_points_tsumo()
        elif self.ending == RoundEnding.ExhaustiveDraw:
            return self._compute_points_exhaustive_draw()
        elif self.ending.is_abortive_draw:
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
        elif self.ending.is_abortive_draw:
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
