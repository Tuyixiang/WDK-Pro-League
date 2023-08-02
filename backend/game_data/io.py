from __future__ import annotations

import dataclasses
import gzip
import json
from dataclasses import dataclass
from datetime import date, datetime
from typing import (
    Any,
    Type,
    TypeVar,
    Union,
    get_args,
    get_origin,
    get_type_hints,
)

T = TypeVar("T", bound="Deserializable")


@dataclass
class Deserializable:
    """实现递归的从 JSON 对象构建（仅针对 dataclass 及基础类型）"""

    @staticmethod
    def deserialize_object(ty: type, obj: Any) -> Any:
        """读取对象并转化为指定的类型"""
        if get_origin(ty) is Union:
            ty = get_args(ty)[0]
            return Deserializable.deserialize_object(ty, obj)
        if get_origin(ty) is list:
            ty = get_args(ty)[0]
            return [Deserializable.deserialize_object(ty, item) for item in obj]
        if get_origin(ty) is dict:
            key_type, value_type = get_args(ty)
            return {
                Deserializable.deserialize_object(
                    key_type, key
                ): Deserializable.deserialize_object(value_type, value)
                for key, value in obj.items()
            }
        if issubclass(ty, Deserializable):
            return ty.deserialize(obj)
        if issubclass(ty, datetime):
            return datetime.fromisoformat(obj)
        return ty(obj)

    @classmethod
    def deserialize(cls: Type[T], obj: dict) -> T:
        """读取对象并转化为当前类型"""
        kwargs = {}
        type_hints = get_type_hints(cls)
        for field in dataclasses.fields(cls):
            if not field.repr:
                continue
            name = field.name
            if name not in obj:
                continue
            if obj[name] is None:
                kwargs[name] = None
                continue
            kwargs[name] = cls.deserialize_object(type_hints[name], obj[name])
        return cls(**kwargs)

    @classmethod
    def read_compressed_file(cls: Type[T], path: str) -> T:
        """从指定的文件中读取对象"""
        with gzip.open(path, "rt") as file:
            obj = json.load(file)
            return cls.deserialize(obj)

    @staticmethod
    def serialize_object(obj: Any, exclude_non_repr: bool = True) -> Any:
        """递归地转化为可以 JSON 序列化的字典对象"""
        if isinstance(obj, Deserializable):
            return obj.serialize(exclude_non_repr=exclude_non_repr)
        if isinstance(obj, list):
            return [
                Deserializable.serialize_object(item, exclude_non_repr=exclude_non_repr)
                for item in obj
            ]
        if isinstance(obj, dict):
            return {
                Deserializable.serialize_object(
                    key, exclude_non_repr=exclude_non_repr
                ): Deserializable.serialize_object(
                    value, exclude_non_repr=exclude_non_repr
                )
                for key, value in obj.items()
            }
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        return obj

    def serialize(self, exclude_non_repr: bool = True) -> dict:
        """递归地转化为可以 JSON 序列化的字典对象

        如果 exclude_repr，则不序列化其中 repr 为 False 的字段
        （保存数据时应为 True，向前端发送数据时应为 False）

        date 和 datetime 会转换为 isoformat 字符串"""
        result = {}
        for field in dataclasses.fields(self):
            if exclude_non_repr and not field.repr:
                continue
            result[field.name] = self.serialize_object(
                getattr(self, field.name), exclude_non_repr=exclude_non_repr
            )
        return result

    def write_compressed_data(self, path: str) -> None:
        """将当前对象压缩保存于指定文件"""
        with gzip.open(path, "wt") as file:
            json.dump(self.serialize(), file)
