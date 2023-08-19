import json
import os
import sys
from dataclasses import dataclass
from datetime import datetime
from pprint import pprint
from typing import Callable

from .io import Deserializable
from .player import PlayerDatabase, player_database
from .game import *


def paipu_parse_id(obj) -> str:
    """从雀魂牌谱中解析外部 ID"""
    return obj["gamedata"]["uuid"]


def tenhou_parse_id(obj) -> str:
    """从天凤牌谱中解析外部 ID"""
    return obj["ref"]


def offline_parse_id(obj) -> str:
    """从线下 JSON 中生成游戏 ID"""
    return f"{obj['game_date']} {':'.join(obj['player_ids'])}"


def paipu_parse_timestamp(obj) -> datetime:
    """从雀魂牌谱中解析时间戳"""
    return datetime.fromtimestamp(obj["gamedata"]["starttime"])


def tenhou_parse_timestamp(obj) -> datetime:
    """从天凤牌谱中解析时间戳"""
    # 不同保存方式可能采用不同的时间戳格式
    try:
        return datetime.strptime(obj["title"][1], r"%m/%d/%Y, %I:%M:%S %p")
    except ValueError:
        return datetime.strptime(obj["title"][1], r"%Y/%m/%d %H:%M:%S")


def offline_parse_timestamp(obj) -> datetime:
    """从线下 JSON 中解析时间戳"""
    return datetime.fromisoformat(obj["game_date"])


@dataclass
class GameDataController(Deserializable):
    """积分计算规则"""

    game_database: GameDatabase

    player_database: PlayerDatabase

    def apply_game(self, game: GameData):
        """将游戏保存，并更新玩家数据"""

        game.print_log()

        self.game_database.add_game(game)

        for player in game.players:
            self.player_database.get_player(player.player_id).add_game(game.preview)

    def load_from_paipu_json(self, game_obj: dict):
        """从 JSON 对象中读取并保存游戏

        使用 https://github.com/zyr17/MajsoulPaipuAnalyzer 生成的牌谱"""
        # 检查是否已经存在相同的游戏
        external_game_id = paipu_parse_id(game_obj)
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
                        external_ids=[external_player_id],
                    )
                )

        # 创建游戏
        game = GameData(
            players=[p.snapshot for p in players],
            player_points=[
                int(x) for x in game_obj["record"][-1]["action"][-1][1:].split("|")
            ],
            game_date=paipu_parse_timestamp(game_obj),
            external_id=external_game_id,
            game_type=MAJSOUL_GAME,
        )

        # 保存游戏
        self.apply_game(game)

    def load_from_tenhou_json(self, game_obj: dict):
        """从 JSON 对象（天凤格式）中读取并保存游戏"""
        # 检查是否已经存在相同的游戏
        external_game_id = game_obj["ref"]
        if external_game_id in self.game_database.external_id_set:
            return

        # 读取玩家列表，如果不存在则创建新雀魂玩家
        players = []
        for external_player_name in game_obj["name"]:
            if external_player_name in self.player_database.external_name_map:
                players.append(
                    self.player_database.external_name_map[external_player_name]
                )
            else:
                players.append(
                    self.player_database.create_player(
                        player_name=f"雀魂玩家-{external_player_name}",
                        external_names=[external_player_name],
                    )
                )

        # 创建游戏
        game = GameData(
            players=[p.snapshot for p in players],
            player_points=game_obj["sc"][::2],
            rounds=[TenhouRound.from_json(r) for r in game_obj["log"]],
            game_date=tenhou_parse_timestamp(data),
            external_id=external_game_id,
            game_type=MAJSOUL_GAME,
        )

        # 保存游戏
        self.apply_game(game)

    def load_from_offline_json(self, game_obj: dict):
        """从 JSON 对象读取并保存线下游戏"""
        # 检查是否已经存在相同的游戏
        external_game_id = offline_parse_id(game_obj)
        if external_game_id in self.game_database.external_id_set:
            return

        # 读取玩家列表，如果不存在则创建新雀魂玩家
        players = []
        for player_id in game_obj["player_ids"]:
            if player_id in self.player_database.all_player_data:
                players.append(self.player_database.get_player(player_id))
            else:
                players.append(
                    self.player_database.create_player(
                        player_name=f"线下玩家-{player_id}",
                        player_id=player_id,
                    )
                )

        # 创建游戏
        game = GameData(
            players=[p.snapshot for p in players],
            player_points=game_obj["player_points"],
            game_date=offline_parse_timestamp(game_obj),
            external_id=external_game_id,
            game_type=GameType.Enum.get(game_obj["game_type"], OFFLINE_GAME),
        )

        # 保存游戏
        self.apply_game(game)


game_controller = GameDataController(game_database, player_database)

# 读取牌谱
# 先加载文件并记录游戏时间，然后按照时间进行排序再处理
game_json_objs = []
new_game_ids = set()


def load_from_directory(
    directory: str,
    loader: Callable[[dict], None],
    timestamp_parser: Callable[[dict], datetime],
    id_parser: Callable[[dict], str],
):
    try:
        for file in os.listdir(directory):
            path = os.path.join(directory, file)
            try:
                data = json.load(open(path))
                timestamp = timestamp_parser(data)
                external_id = id_parser(data)
                # 去重
                if (
                    external_id in new_game_ids
                    or external_id in game_database.external_id_set
                ):
                    continue
                new_game_ids.add(external_id)
                game_json_objs.append(
                    (
                        timestamp,
                        external_id,
                        loader,
                        data,
                    )
                )
            except (json.JSONDecodeError, KeyError, TypeError, ValueError) as e:
                print(f"加载牌谱：无法读取 {path}", file=sys.stderr)
                print(e)
                continue
    except FileNotFoundError:
        print(f"无牌谱目录 {directory}", file=sys.stderr)


# 读取天凤牌谱
load_from_directory(
    "data/tenhou",
    game_controller.load_from_tenhou_json,
    tenhou_parse_timestamp,
    tenhou_parse_id,
)
# 读取雀魂牌谱
load_from_directory(
    "data/paipu",
    game_controller.load_from_paipu_json,
    paipu_parse_timestamp,
    paipu_parse_id,
)
# 读取线下牌谱
load_from_directory(
    "data/offline",
    game_controller.load_from_offline_json,
    offline_parse_timestamp,
    offline_parse_id,
)
# 排序并处理
for _, external_id, func, data in sorted(game_json_objs, key=lambda x: x[0]):
    try:
        func(data)
    except (TypeError, KeyError) as e:
        print(f"加载牌谱{repr(external_id)}失败：数据类型错误", file=sys.stderr)
        print(e)
