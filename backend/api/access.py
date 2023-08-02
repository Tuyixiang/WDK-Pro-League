from flask import Blueprint, request, jsonify

from game_data import player_database, game_database, Deserializable

access_blueprint = Blueprint("/api/access", __name__)
"""/api/access"""


@access_blueprint.route("/leader_board")
def get_leader_board():
    """获取排行榜"""
    player_database.update()
    return jsonify(
        Deserializable.serialize_object(
            player_database.leader_board, exclude_non_repr=False
        )
    )


@access_blueprint.route("/game_history")
def get_game_history():
    """获取所有历史游戏列表"""
    return jsonify(
        Deserializable.serialize_object(
            game_database.game_history, exclude_non_repr=False
        )
    )
