from flask import Blueprint, request, jsonify

from game_data import player_database, game_database
from .error import *

query_blueprint = Blueprint("/api/query", __name__)
"""/api/query"""


@query_blueprint.route("/player")
def query_player():
    """获取玩家信息，参数：{"player_id": str}"""
    try:
        player_id = request.args.get("player_id")
        player = player_database.get_player(player_id)
        return jsonify(player.serialize(exclude_non_repr=False))
    except KeyError:
        raise InvalidIdException()


@query_blueprint.route("/game")
def query_game():
    """获取游戏信息，参数：{"game_id": str}"""
    try:
        game_id = request.args.get("game_id")
        game = game_database.get_game(game_id)
        return jsonify(game.serialize(exclude_non_repr=False))
    except KeyError:
        raise InvalidIdException()
