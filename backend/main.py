from datetime import timedelta
from pprint import pprint

from flask import Flask, send_from_directory, request
from flask_cors import CORS
from api import *
from api.access import get_leader_board
from data.keys import KEY_HASHED
from hashlib import sha3_256

app = Flask(__name__)
CORS(app)


@access_blueprint.before_request
@query_blueprint.before_request
def check_key():
    """检查密钥，如不符合则拒绝访问"""
    try:
        key = request.cookies.get("key")
        hashed = sha3_256(bytes.fromhex(key)).digest()
        if hashed == KEY_HASHED:
            return
    except (TypeError, ValueError):
        pass
    return no_key_handler()


# 访问路径
app.register_blueprint(access_blueprint, url_prefix="/api/access")
app.register_blueprint(query_blueprint, url_prefix="/api/query")

# 错误处理
app.register_error_handler(InvalidIdException, invalid_id_handler)


@app.route("/<path:path>")
def static_serve(path):
    return send_from_directory("static", path)


@app.route("/")
def static_serve_index():
    response = app.send_static_file("index.html")
    key = request.args.get("key")
    if key:
        response.set_cookie("key", key, max_age=timedelta(days=365))
    return response


with app.app_context():
    pprint(get_leader_board().json)
