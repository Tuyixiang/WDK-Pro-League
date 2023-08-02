from dataclasses import dataclass, field
from typing import Any, List

from .io import Deserializable


@dataclass
class PlayerSnapshot(Deserializable):
    """一个玩家在进行某一局游戏时的状态（保存为游戏的一部分，应当包含游戏计算分数所需的所有信息）"""

    player_id: str
    """数据保存用的 id"""

    player_name: str
    """玩家登陆及显示名称"""

    current_dan: int
    """当前的段位（0 表示一段）"""

    current_pt: int
    """当前的分数"""

    threshold_pt: int
    """升段所需的分数"""

    r_value: float
    """根据天凤规则计算 R 值"""

    game_count: int
    """进行的游戏局数"""

    order_count: List[int]
    """获得相应顺位的次数"""

    def __eq__(self, other: Any) -> bool:
        return self.player_id == other.player_id

    def __str__(self) -> str:
        return f'"{self.player_name}"({self.current_dan} {self.current_pt}/{self.threshold_pt})'
