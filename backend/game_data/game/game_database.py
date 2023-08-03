from __future__ import annotations

import os
import sys
from dataclasses import dataclass, field
from typing import Dict, List, Set

from ..io import *
from .game_data import GameData
from ..game_preview import GamePreview

_DEFAULT_DATABASE_PATH = "game.db"


@dataclass
class GameDatabase(Deserializable):
    """存储所有游戏记录"""

    database_path: str
    """存储文件地址"""

    all_game_data: Dict[str, GameData]
    """所有游戏记录"""

    game_history: List[GamePreview] = field(init=False, repr=False)
    """按时间顺序排列的游戏记录，缓存变量"""

    external_id_set: Set[str] = field(init=False, repr=False)
    """所有外部链接的集合，为防止重复添加"""

    def __post_init__(self):
        self.update()

    def update(self) -> None:
        """更新所有缓存变量"""
        self.game_history = [
            game.preview
            for game in sorted(
                self.all_game_data.values(),
                key=lambda game: game.game_date or game.upload_time,
            )
        ]
        self.external_id_set = {
            game.external_id
            for game in self.all_game_data.values()
            if game.external_id is not None
        }

    def save(self):
        """保存到文件"""
        self.write_compressed_data(self.database_path)

    def add_game(self, game_data: GameData):
        """添加新游戏，并更新玩家分数（默认放在最后）"""
        game_id = game_data.game_id
        assert game_id not in self.all_game_data
        self.all_game_data[game_id] = game_data
        self.update()

    def get_game(self, game_id: str) -> GameData:
        return self.all_game_data[game_id]


try:
    game_database = GameDatabase.read_compressed_file(_DEFAULT_DATABASE_PATH)
    """全局游戏记录管理"""
except FileNotFoundError:
    game_database = GameDatabase(_DEFAULT_DATABASE_PATH, {})
