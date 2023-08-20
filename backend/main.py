import os
from datetime import timedelta
from pprint import pprint

from flask import Flask, send_from_directory
from flask_cors import CORS
from api import *
from data.keys import KEY_HASHED
from hashlib import sha3_256

app = Flask(__name__)

IS_DEVELOPMENT_MODE = os.getenv("FLASK_ENV") == "development"
"""开发环境"""

if IS_DEVELOPMENT_MODE:
    CORS(app)


# 访问路径
app.register_blueprint(access_blueprint, url_prefix="/api/access")
app.register_blueprint(query_blueprint, url_prefix="/api/query")
app.register_blueprint(post_blueprint, url_prefix="/api/post")

# 错误处理
app.register_error_handler(InvalidIdException, invalid_id_handler)


@app.before_request
def check_key():
    """检查密钥，如不符合则拒绝访问"""
    if IS_DEVELOPMENT_MODE:
        return
    try:
        key = request.args.get("key") or request.cookies.get("key")
        hashed = sha3_256(bytes.fromhex(key)).digest()
        if hashed == KEY_HASHED:
            return
    except (TypeError, ValueError):
        pass
    return no_key_handler()


@app.after_request
def save_key_to_cookie(response):
    """如果请求包含密钥，则将其保存至 cookie 中"""
    if IS_DEVELOPMENT_MODE:
        return response
    key = request.args.get("key")
    if key:
        response.set_cookie("key", key, max_age=timedelta(days=365), secure=True)
    return response


@app.route("/<path:path>")
def static_serve(path):
    return send_from_directory("static", path)


@app.route("/")
def static_serve_index():
    response = app.send_static_file("index.html")
    return response


with app.app_context():
    print(f"App 已启动")
    if IS_DEVELOPMENT_MODE:
        print(f"（开发模式）")
