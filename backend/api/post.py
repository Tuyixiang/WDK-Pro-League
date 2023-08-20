import json

from flask import Blueprint, request, jsonify

from game_data import game_controller
from .error import *

post_blueprint = Blueprint("/api/post", __name__)
"""/api/post"""


@post_blueprint.route("/game", methods=["POST"])
def upload_game():
    """上传天凤 JSON 文件（POST 上传 {"data": ...}）"""
    try:
        data = request.form["data"]
        game_controller.load_from_tenhou_json(json.loads(data))
        game_controller.save()
        return {"status": "ok"}, 200
    except (TypeError, KeyError, json.JSONDecodeError):
        return bad_data_handler()
