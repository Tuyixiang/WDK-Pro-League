import json
from pprint import pprint

from flask import Blueprint, request, jsonify

from game_data import game_controller, tenhou_parse_id
from .error import *

post_blueprint = Blueprint("/api/post", __name__)
"""/api/post"""


@post_blueprint.route("/tenhou_game", methods=["POST"])
def upload_tenhou_game():
    """上传天凤 JSON 文件

    上传格式：{key1: game_json, key2: game_json, ...}
    返回格式：{key1: "ok", key2: "error_msg", ...}
    """
    try:
        payload = json.loads(request.data.decode())
        assert isinstance(payload, dict)
    except (UnicodeDecodeError, json.JSONDecodeError, AssertionError):
        return bad_data_handler()
    result = {}
    for key, game_json in payload.items():
        try:
            game_obj = json.loads(game_json)
            external_id = tenhou_parse_id(game_obj)
            if external_id in game_controller.game_database.external_id_map:
                result[key] = "游戏数据已存在"
                continue
            game_controller.load_from_tenhou_json(json.loads(game_json))
            with open(f"data/tenhou/upload-{external_id}.json", "w") as f:
                f.write(game_json)
            # game_controller.save()
            result[key] = "上传成功"
        except (TypeError, KeyError, json.JSONDecodeError):
            result[key] = "解析失败"
    return result, 200
