from flask import Flask, send_from_directory
from flask_cors import CORS
from api import *

app = Flask(__name__)
CORS(app)

# 访问路径
app.register_blueprint(access_blueprint, url_prefix="/api/access")
app.register_blueprint(query_blueprint, url_prefix="/api/query")

# 错误处理
app.register_error_handler(InvalidIdException, invalid_id_handler)


@app.route("/api")
def hello_world():
    return "<p>Hello, World!</p>"


@app.route("/<path:path>")
def static_serve(path):
    print("he")
    return send_from_directory("static", path)


@app.route("/")
def static_serve_index():
    return app.send_static_file("index.html")
