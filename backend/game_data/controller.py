import json
import os
import sys
from dataclasses import dataclass
from datetime import datetime

from .io import Deserializable
from .player import PlayerDatabase, player_database
from .game import GameData, GameDatabase, game_database


_PAIPU_PATH = "data/paipus"


@dataclass
class GameDataController(Deserializable):
    """积分计算规则"""

    game_database: GameDatabase

    player_database: PlayerDatabase

    def apply_game(self, game: GameData):
        """将游戏保存，并更新玩家数据"""

        game.print_log()

        self.game_database.add_game(game)

        for player, pt, r in zip(game.players, game.pt_delta, game.r_delta):
            self.player_database.get_player(player.player_id).add_game(game.preview)

    def load_from_json(self, game_obj: dict):
        """从 JSON 对象中读取并保存游戏"""
        # 检查是否已经存在相同的游戏
        external_game_id = game_obj["gamedata"]["uuid"]
        if external_game_id in self.game_database.external_id_set:
            return

        # 读取玩家列表，如果不存在则创建新雀魂玩家
        players = []
        for ext_player_data in game_obj["gamedata"]["playerdata"]:
            external_player_id = ext_player_data["id"]
            if external_player_id in self.player_database.external_id_map:
                players.append(self.player_database.external_id_map[external_player_id])
            else:
                players.append(
                    self.player_database.create_player(
                        player_name=f"雀魂玩家-{ext_player_data['name']}",
                        external_id=[external_player_id],
                    )
                )

        # 创建游戏
        game = GameData(
            players=[p.snapshot for p in players],
            player_points=[
                int(x) for x in game_obj["record"][-1]["action"][-1][1:].split("|")
            ],
            game_date=datetime.fromtimestamp(game_obj["gamedata"]["starttime"]),
            external_id=external_game_id,
        )

        # 保存游戏
        self.apply_game(game)


game_controller = GameDataController(game_database, player_database)

# 读取牌谱
try:
    # 先加载文件并记录游戏时间，然后按照时间进行排序再处理
    game_json_objs = []
    for file in os.listdir(_PAIPU_PATH):
        path = os.path.join(_PAIPU_PATH, file)
        try:
            data = json.load(open(path))
        except json.JSONDecodeError:
            print(f"加载牌谱：JSON 无法读取 {path}", file=sys.stderr)
            continue
        game_json_objs.append(data)
    # 排序并处理
    game_json_objs = [
        x
        for x in game_json_objs
        if isinstance(x, dict)
        and isinstance(x["gamedata"], dict)
        and isinstance(x["gamedata"]["starttime"], int)
    ]
    game_json_objs.sort(key=lambda x: x["gamedata"]["starttime"])
    for game_obj in game_json_objs:
        try:
            game_controller.load_from_json(game_obj)
        except (TypeError, KeyError):
            print(f"加载牌谱：数据类型错误", file=sys.stderr)
except FileNotFoundError:
    print(f"无牌谱目录 {_PAIPU_PATH}", file=sys.stderr)
