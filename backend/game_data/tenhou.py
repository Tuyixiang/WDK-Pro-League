"""天凤牌局解析"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import List, Optional, Union

from game_data import Deserializable


TILE_ORDER = {
    f"{v}{s}": i * 10 + j
    for i, s in enumerate("mpsz")
    for j, v in enumerate("1234056789")
}


class RoundSimulationFailure(Exception):
    """模拟牌局失败，可能是牌局格式不正确"""


def sorted_tiles(tiles: List[str]) -> List[str]:
    """对麻将牌进行排序"""
    return sorted(tiles, key=lambda t: TILE_ORDER[t])


def parse_tenhou_tile(value: int) -> str:
    """从天凤的数字中解析麻将牌"""
    if value < 50:
        return f"{value % 10}{'mpsz'[value // 10 - 1]}"
    return f"0{'mps'[value - 51]}"


class MeldType(Enum):
    """副露类型"""

    Chi = auto()
    Pon = auto()
    Kan = auto()
    """大明杠"""
    Chakan = auto()
    """加杠"""
    Ankan = auto()
    """暗杠"""


class Meld(list):
    """副露

    第一项表示 meld[i] 是横置的，后面为从左到右摆放顺序
    吃：[1, "4m", "3m", "0m"] 来自上家的 4m（第一项必为 1）
    碰：[3, "1z", "1z", "1z"] 来自下家的 1z
    大明杠：[-4, "0m", "5m", "5m", "5m"] 来自上家的 0m（第一项为 -4, -3, -1）用负数区分
    加杠：[3, "1z", "1z", "1z", "1z"] 在碰的基础上后端插入一个元素，故第一项为 1,2,3
    暗杠：[0, "1z", "1z", "1z", "1z"]
    """

    @property
    def type(self) -> MeldType:
        if len(self) == 4:
            if self[1] == self[2] or self[2] == self[3] or self[1] == self[3]:
                return MeldType.Pon
            return MeldType.Chi
        if len(self) == 5:
            if self[0] > 0:
                return MeldType.Chakan
            elif self[0] == 0:
                return MeldType.Ankan
            else:
                return MeldType.Kan
        raise RoundSimulationFailure()

    def from_seat(self, seat: int) -> int:
        """所叫得弃张的来源"""
        if self[0] > 0:
            return (seat - self[0]) % 4
        if self[0] == 0:
            return seat
        return (seat - [1, 2, 0, 3][self[0]]) % 4

    @property
    def used_tiles(self) -> List[str]:
        """使用到的手中的牌"""
        meld_type = self.type
        if type in [MeldType.Chi, MeldType.Pon]:
            return [self[i] for i in range(1, len(self)) if i != self[0]]
        if type == MeldType.Kan:
            return [self[i] for i in range(1, len(self)) if i != self[0] + len(self)]
        if type == MeldType.Chakan:
            return self[-1]
        if type == MeldType.Ankan:
            return self[1:]
        raise RoundSimulationFailure()

    @staticmethod
    def _parse_tiles(string: str) -> List[str]:
        """将一串数字（例如"373737"）解析为列表（如 ["7s", "7s", "7s"]）"""
        return [
            parse_tenhou_tile(int(string[i : i + 2])) for i in range(0, len(string), 2)
        ]

    @staticmethod
    def from_tenhou(string: str) -> Meld:
        """从天凤的字符串中解析吃碰杠"""
        try:
            match = re.search(r"[a-z]", string)
            assert match is not None
            index, symbol = match.start(0), match[0]
            if symbol == "c":
                # 吃
                assert index == 0
                return Meld([1] + Meld._parse_tiles(string[1:]))
            if symbol == "p" or symbol == "k":
                # 碰
                string = string[:index] + string[index + 1 :]
                return Meld([index // 2 + 1] + Meld._parse_tiles(string))
            if symbol == "m":
                # 大明杠
                string = string[:index] + string[index + 1 :]
                return Meld([index // 2 - 4] + Meld._parse_tiles(string))
            if symbol == "a":
                # 暗杠
                assert index == 6
                string = string[:index] + string[index + 1 :]
                return Meld([0] + Meld._parse_tiles(string))
        except (ValueError, IndexError, TypeError, AssertionError):
            pass
        raise RoundSimulationFailure()


@dataclass
class RoundPlayerStatus(Deserializable):
    """一个玩家相关的牌"""

    dealer: int
    """庄家座次"""

    seat: int
    """本家座次"""

    hand: List[str]
    """手中的牌"""

    meld: List[Meld] = field(default_factory=list)
    """副露面子、刻子以及暗杠"""

    river: List[str] = field(default_factory=list)
    """牌河，包括被吃碰杠的牌"""

    agari: Optional[str] = field(default=None)
    """和牌"""

    def _remove_from_hand(self, tile: str):
        """从手牌中移除"""
        try:
            self.hand.remove(tile)
        except ValueError:
            raise RoundSimulationFailure

    def discard(self, tile: str):
        """模拟切牌"""
        self._remove_from_hand(tile)
        self.river.append(tile)

    def draw_and_discard(self, draw: str, discard: str):
        """模拟摸牌和切牌"""
        self.hand.append(draw)
        self.discard(discard)

    def call(self, string: str, discard: Optional[str]):
        """模拟吃碰杠"""
        # 添加明牌
        meld = Meld.from_tenhou(string)
        self.meld.append(meld)
        # 从手中移除使用到的牌
        for used_tile in meld.used_tiles:
            self._remove_from_hand(used_tile)
        if discard:
            self.discard(discard)


@dataclass
class RoundFullInfo(Deserializable):
    """牌局完整信息"""

    wind: int
    """场风"""

    dealer: int
    """庄家"""

    honba: int
    """本场数"""

    riichi_status: List[bool]
    """立直状态"""

    kyoutaku: int
    """场供（立直棒数量）"""

    initial_points: List[int]
    """初始点数"""

    initial_hands: List[List[str]]
    """配牌"""

    dora: List[str]
    """宝牌（翻开的指示物）"""

    uradora: List[str]
    """里宝牌"""

    player_final_status: List[RoundPlayerStatus]
    """玩家最后的状态（包括手牌、副露、牌河）"""

    @staticmethod
    def from_json(obj) -> RoundFullInfo:
        round_number, honba, kyoutaku = obj[0]
        wind = round_number // 4
        dealer = round_number % 4
        initial_points = obj[1]
        dora = [parse_tenhou_tile(v) for v in obj[2]]
        uradora = [parse_tenhou_tile(v) for v in obj[3]]
        initial_hands = [
            [parse_tenhou_tile(v) for v in obj[i]] for i in range(4, 16, 3)
        ]
        players = [RoundPlayerStatus(dealer, i, initial_hands[i]) for i in range(4)]
        riichi_status = [False] * 4

        # 开始模拟牌局
        # 摸的牌
        draws: List[List[Union[int, str]]] = [obj[i] for i in range(5, 16, 3)]
        # 切的牌
        discards: List[List[Union[int, str]]] = [obj[i] for i in range(6, 16, 3)]
        # 目前每玩家已进行的巡数
        indices = [0] * 4
        # 当前玩家
        current = dealer

        while indices[current] < len(draws[current]):
            draw_tile = draws[current][indices[current]]
            discard_tile = discards[current][indices[current]]
            indices[current] += 1
            if isinstance(draw_tile, int):
                draw_tile = parse_tenhou_tile(draw_tile)

        return RoundFullInfo(
            wind=wind,
            dealer=dealer,
            honba=honba,
            riichi_status=riichi_status,
            kyoutaku=kyoutaku,
            initial_points=initial_points,
            initial_hands=initial_hands,
            dora=dora,
            uradora=uradora,
            player_final_status=players,
        )
