from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
import dataclasses
from typing import Dict, List

from ..io import Deserializable
from .player_data import PlayerData

_DEFAULT_DATABASE_PATH = "player.db"


@dataclass
class PlayerDatabase(Deserializable):
    """存储所有玩家的游戏信息"""

    database_path: str
    """存储文件地址"""

    all_player_data: Dict[str, PlayerData]
    """所有玩家的记录"""

    external_id_map: Dict[int, PlayerData] = field(init=False, repr=False)
    """利用外部 ID 作为索引，缓存变量"""

    leader_board: list = field(init=False, repr=False)
    """按照名次排序的玩家记录，缓存变量"""

    def __post_init__(self):
        self.update()

    def save(self):
        """保存到文件"""
        self.write_compressed_data(self.database_path)

    def create_player(self, *args, **kwargs) -> PlayerData:
        """创建新玩家并保存至 PlayerDatabase"""
        player = PlayerData.new(*args, **kwargs)
        self.all_player_data[player.player_id] = player
        self.update()
        return player

    def get_player(self, player_id: str) -> PlayerData:
        return self.all_player_data[player_id]

    def update(self):
        """根据当前 all_player_data 更新其他变量"""
        self.leader_board = [
            player.snapshot
            for player in sorted(
                self.all_player_data.values(),
                key=lambda player_data: (
                    player_data.current_dan,
                    player_data.current_pt,
                ),
                reverse=True,
            )
        ]
        self.external_id_map = {
            player.external_id: player
            for player in self.all_player_data.values()
            if player.external_id is not None
        }


try:
    player_database = PlayerDatabase.read_compressed_file(_DEFAULT_DATABASE_PATH)
    """全局游戏记录管理"""
except FileNotFoundError:
    player_database = PlayerDatabase(_DEFAULT_DATABASE_PATH, {})

# 读取预存玩家列表
try:
    initial_players = json.load(open("data/users.json"))
    for player in initial_players:
        if player["player_id"] not in player_database.all_player_data:
            player_database.create_player(**player)
except FileNotFoundError:
    print("未找到预设玩家列表 data/users.json", file=sys.stderr)
    for i in range(8):
        player_database.create_player(f"玩家{chr(i + ord('A'))}", player_id=hex(i))
