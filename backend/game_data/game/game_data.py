from __future__ import annotations

import dataclasses
import sys
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional, Tuple, TextIO
import uuid

from ..game_preview import GamePreview
from ..io import Deserializable

from ..player.player_data import PlayerSnapshot
from .round import RoundResult


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
class GameData(Deserializable):
    """每盘游戏所有保存的数据"""

    players: List[PlayerSnapshot]
    """参与的玩家，按照座位顺序"""

    player_points: List[int]
    """每个玩家获得的点数（当盘游戏的点数，非玩家累计点数）"""

    rounds: List[RoundResult] = field(default_factory=list)
    """每一局的结果，可能为空（只计点数）"""

    game_date: Optional[datetime] = field(default=None)
    """实际进行游戏的日期"""

    external_id: Optional[str] = field(default=None)
    """游戏细节的外部链接，如果适用"""

    game_id: str = field(default_factory=lambda: uuid.uuid4().hex)
    """Index 所用的唯一 key"""

    upload_time: datetime = field(default_factory=datetime.now)
    """上传时间（以服务器接受为准）"""

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
    def player_order_by_id(self) -> List[str]:
        """参与玩家的游戏结果排序"""
        return [p.player_id for p, _ in self.sorted_player_points]

    def __post_init__(self):
        self.update()

    def update(self):
        """计算分数和 R"""
        self.pt_delta = [0, 0, 0, 0]
        self.r_delta = [0, 0, 0, 0]

        sorted_player_points = self.sorted_player_points

        # 被飞的玩家
        out_players = [p for p, point in sorted_player_points if point < 0]

        average_r = sum(p.r_value for p in self.players) / 4

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
                for round in self.rounds:
                    for win in round.wins:
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
            r *= 1 - player.game_count / 500

            self.pt_delta[seat] = pt
            self.r_delta[seat] = r

    def print_log(self, out: TextIO = sys.stdout):
        print(
            f"Game {self.game_id}\n",
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
