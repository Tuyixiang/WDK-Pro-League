from flask import Flask
from api import *

app = Flask(__name__)

# 访问路径
app.register_blueprint(access_blueprint, url_prefix="/api/access")
app.register_blueprint(query_blueprint, url_prefix="/api/query")

# 错误处理
app.register_error_handler(InvalidIdException, invalid_id_handler)


@app.route("/api")
def hello_world():
    return "<p>Hello, World!</p>"
