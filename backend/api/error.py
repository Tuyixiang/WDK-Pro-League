"""错误信息"""


class InvalidIdException(Exception):
    pass


def invalid_id_handler(e: InvalidIdException):
    return {"error": "Invalid ID"}, 400
