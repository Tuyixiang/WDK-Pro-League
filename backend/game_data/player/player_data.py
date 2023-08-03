from __future__ import annotations

import uuid
import dataclasses
from dataclasses import dataclass, field
from typing import List

from ..player_snapshot import PlayerSnapshot
from ..game_preview import GamePreview
from ..io import Deserializable


N_DAN = 10
"""段位数量"""

DAN_INITIAL_PT = [200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000]
"""段位初始分数"""

DAN_THRESHOLD = [400, 800, 1200, 1600, 2000, 2400, 2800, 3200, 3600, 4000]
"""段晋级所需分数（[0]是晋级二段所需分数）"""

NEW_PLAYER_PT = 200
"""新玩家的初始分数"""

NEW_PLAYER_R = 1500
"""新玩家的初始 R 值"""


@dataclass
class PlayerData(Deserializable):
    """一个玩家的累积数据"""

    player_id: str
    """数据保存用的 id"""

    player_name: str
    """玩家登陆及显示名称"""

    external_ids: List[int]
    """玩家外部游戏 ID"""

    game_history: List[GamePreview]
    """玩家历史所有游戏"""

    current_dan: int
    """当前的段位（0 表示一段）"""

    highest_dan: int
    """最高达到的段位"""

    current_pt: int
    """当前的分数"""

    highest_dan_pt: int
    """最高段位下最高分数"""

    r_value: float
    """根据天凤规则计算 R 值
    
    参考：https://zhuanlan.zhihu.com/p/32538095"""

    titles: List[str] = field(default_factory=list)
    """玩家称号"""

    threshold_pt: int = field(init=False, repr=False)
    """升段所需的分数，缓存变量"""

    game_count: int = field(init=False, repr=False)
    """进行的游戏局数，缓存变量"""

    order_count: List[int] = field(init=False, repr=False)
    """获得相应顺位的次数"""

    @staticmethod
    def new(
        player_name: str, external_id: List[int] = None, player_id: str = None
    ) -> PlayerData:
        """创建一个新玩家"""
        return PlayerData(
            player_id=player_id or uuid.uuid4().hex,
            player_name=player_name,
            external_ids=external_id or [],
            game_history=[],
            current_dan=0,
            highest_dan=0,
            current_pt=NEW_PLAYER_PT,
            highest_dan_pt=NEW_PLAYER_PT,
            r_value=NEW_PLAYER_R,
        )

    def __post_init__(self):
        self.update()

    def update_dan(self):
        """根据分数计算段位晋级、降级"""
        self.threshold_pt = DAN_THRESHOLD[self.current_dan]
        self.current_dan = min(max(self.current_dan, 0), N_DAN)
        if self.current_pt >= self.threshold_pt:
            # 升段
            if self.current_dan < N_DAN - 1:
                self.current_dan += 1
                if self.highest_dan < self.current_dan:
                    self.highest_dan = self.current_dan
                    self.highest_dan_pt = DAN_INITIAL_PT[self.current_dan]
                self.current_pt = DAN_INITIAL_PT[self.current_dan]
            else:
                self.current_pt = self.threshold_pt
        elif self.current_pt < 0:
            # 降段
            if self.current_dan > 0:
                self.current_dan -= 1
                self.current_pt = DAN_INITIAL_PT[self.current_dan]
            else:
                self.current_pt = 0
        elif self.current_dan == self.highest_dan:
            self.highest_dan_pt = max(self.highest_dan_pt, self.current_pt)
        self.threshold_pt = DAN_THRESHOLD[self.current_dan]

    def update_stats_from_game(self, game: GamePreview):
        """仅使用一个新游戏，更新游戏统计变量"""
        self.game_count += 1
        order = game.player_order_by_id.index(self.player_id)
        self.order_count[order] += 1

    def update(self):
        """完整更新计算缓存变量"""
        self.update_dan()
        # 统计胜场
        self.game_count = 0
        self.order_count = [0, 0, 0, 0]
        for game in self.game_history:
            self.update_stats_from_game(game)

    def reset(self):
        """清除所有游戏记录和分数（仅用于全部重新计算分数！）"""
        self.current_pt = NEW_PLAYER_PT
        self.highest_dan_pt = NEW_PLAYER_PT
        self.current_dan = 0
        self.highest_dan = 0
        self.game_history = []

    def add_game(self, game: GamePreview):
        """添加一盘游戏，并更新分值"""
        seat = game.players.index(self)
        self.game_history.append(game)
        self.current_pt += game.pt_delta[seat]
        self.r_value += game.r_delta[seat]

        self.update_dan()
        self.update_stats_from_game(game)

    @property
    def snapshot(self) -> PlayerSnapshot:
        """返回部分玩家数据在当前瞬间的复制，用于记录在游戏中"""
        fields = dataclasses.fields(PlayerSnapshot)
        return PlayerSnapshot(**{f.name: getattr(self, f.name) for f in fields})

    def __str__(self) -> str:
        return f'"{self.player_name}"({self.current_dan} {self.current_pt}/{self.threshold_pt})'
