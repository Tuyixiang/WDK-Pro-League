from __future__ import annotations

import dataclasses
import sys
from collections import namedtuple
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional, Tuple, TextIO, Dict, ClassVar
import uuid

from ..game_preview import GamePreview
from ..io import Deserializable

from ..player.player_data import PlayerSnapshot
from .round import RoundResult, BaseRound

N_DAN = 10
"""段位数量"""

PT_DELTA = [
    [90 for _ in range(N_DAN)],
    [45 for _ in range(N_DAN)],
    [0 for _ in range(N_DAN)],
    [-45, -60, -75, -90, -105, -120, -135, -150, -165, -180],
]
"""不同顺位、不同段位的得分"""

R_DELTA = [30, 10, -10, -30]
"""不同顺位的 R 值得分"""


@dataclass
class GameType(Deserializable):
    """游戏类型"""

    Enum: ClassVar[Dict[str, GameType]] = {}
    """利用 name 反向查找对应的对象"""

    name: str
    """游戏类型显示名称"""

    pt_multiplier: float = field(default=1)
    """点数的乘数系数"""

    r_multiplier: float = field(default=1)
    """r 点的乘数系数"""

    uma: Optional[List[int]] = field(default=None)
    """马点计算方式，例如 [10000, 20000, 30000, 40000]（如果不按马点计算则为 None）"""

    def __post_init__(self):
        """将创建过的对象自动保存到 Enum 中"""
        if self.name not in GameType.Enum:
            GameType.Enum[self.name] = self


MAJSOUL_GAME_SOUTH4 = GameType(name="雀魂牌局-四人南")
MAJSOUL_GAME_EAST4 = GameType(name="雀魂牌局-四人东", pt_multiplier=2 / 3)
MAJSOUL_GAME_DEFAULT = MAJSOUL_GAME_SOUTH4

OFFLINE_GAME_SOUTH4 = GameType(name="线下牌局-四人南", pt_multiplier=4 / 3)
OFFLINE_GAME_EAST4 = GameType(name="线下牌局-四人东", pt_multiplier=8 / 9)
OFFLINE_GAME_DEFAULT = OFFLINE_GAME_SOUTH4

MAJSOUL_LEAGUE_GAME = GameType(name="雀魂联赛牌局", uma=[10000, 20000, 30000, 40000])
OFFLINE_LEAGUE_GAME = GameType(
    name="线下联赛牌局", pt_multiplier=4 / 3, uma=[10000, 20000, 30000, 40000]
)


@dataclass
class GameData(Deserializable):
    """每盘游戏所有保存的数据"""

    players: List[PlayerSnapshot]
    """参与的玩家，按照座位顺序"""

    player_points: List[int]
    """每个玩家获得的点数（当盘游戏的点数，非玩家累计点数）"""

    game_type: GameType
    """游戏的类型"""

    rounds: List[BaseRound] = field(default_factory=list)
    """每一局的结果，可能为空（只计点数）"""

    game_date: Optional[datetime] = field(default=None)
    """实际进行游戏的日期"""

    external_id: Optional[str] = field(default=None)
    """游戏细节的外部链接，如果适用"""

    game_id: str = field(default_factory=lambda: uuid.uuid4().hex)
    """Index 所用的唯一 key"""

    upload_time: datetime = field(default_factory=datetime.now)
    """上传时间（以服务器接受为准）"""

    yakuman_count: Optional[List[int]] = field(default=None)
    """每个玩家的役满次数，手动输入时使用。如果存在 rounds 则不适用"""

    pt_delta: List[int] = field(init=False, repr=False)
    """玩家获得的分数，缓存变量"""

    r_delta: List[float] = field(init=False, repr=False)
    """玩家获得的 R，缓存变量"""

    @property
    def sorted_player_points(self) -> List[Tuple[PlayerSnapshot, int]]:
        """玩家及游戏分数，按照分数倒序排列"""
        return sorted(
            zip(self.players, self.player_points), key=lambda x: x[1], reverse=True
        )

    @property
    def player_order(self) -> List[PlayerSnapshot]:
        """参与玩家的游戏结果排序"""
        return [p for p, _ in self.sorted_player_points]

    @property
    def ordered_player_ids(self) -> List[str]:
        """参与玩家的游戏结果排序"""
        return [p.player_id for p, _ in self.sorted_player_points]

    @property
    def date(self) -> datetime:
        """进行游戏的日期，或上传记录的日期"""
        return self.game_date or self.upload_time

    def __post_init__(self):
        self.update()

    def update(self):
        """计算分数和 R"""
        self.pt_delta = [0, 0, 0, 0]
        self.r_delta = [0, 0, 0, 0]

        sorted_player_points = self.sorted_player_points

        # 被飞的玩家
        out_players = [p for p, point in sorted_player_points if point < 0]

        # 桌平均R < 1500时，桌平均R视为1500
        average_r = max(1500, sum(p.r_value for p in self.players) / 4)

        for order, (player, player_point) in enumerate(sorted_player_points):
            seat = self.players.index(player)
            # 基础得分
            pt = PT_DELTA[order][player.current_dan]

            # 有玩家被飞，则比其段位低且低于 5 段的玩家 +45pt
            if (
                len(out_players) > 0
                and player_point > 0
                and player.current_dan < 5
                and player.current_dan < max(p.current_dan for p in out_players)
            ):
                pt += 45

            # 低于 5 段玩家每和出一倍役满 +90pt
            if player.current_dan < 5:
                if self.yakuman_count is not None:
                    pt += 90 * self.yakuman_count[seat]
                else:
                    for round_ in self.rounds:
                        for win in round_.wins:
                            if win.winner == seat and win.yakuman > 0:
                                pt += 90 * win.yakuman

            # 低于 5 段玩家，顺位每比段位高 >=2 的玩家高一位，+15pt
            if player.current_dan < 5:
                for delta, other_player in enumerate(self.player_order[order:]):
                    if other_player.current_dan - player.current_dan >= 2:
                        pt += 15 * delta

            # 计算 R 值
            r = R_DELTA[order]
            r += (average_r - player.r_value) / 40

            # 修正值 = (1 - 局数 * 0.002), 400局以上为0.2
            r *= max(0.2, 1 - player.game_count / 500)

            self.pt_delta[seat] = round(pt * self.game_type.pt_multiplier)

            # R 值计算结果进位至第三位小数
            self.r_delta[seat] = round(r * self.game_type.r_multiplier, 3)

    def print_log(self, out: TextIO = sys.stdout):
        print(
            f"{self.game_type.name} {self.game_id}\n",
            "\n".join(
                f"{self.players[i]}: {self.player_points[i]} ({self.pt_delta[i]:+}pt {self.r_delta[i]:+.2f}R)"
                for i in range(4)
            ),
            sep="",
            file=out,
        )

    @property
    def preview(self) -> GamePreview:
        """返回摘要信息"""
        fields = dataclasses.fields(GamePreview)
        return GamePreview(**{f.name: getattr(self, f.name) for f in fields})
