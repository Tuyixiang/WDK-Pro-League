"""天凤牌局解析"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import List, Optional, Union, Tuple

from ..io import Deserializable


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


def parse_tenhou_meld(string: str) -> Tuple[List[str], str, int]:
    """从例如 p313131 的字符串中解析，返回副露、所吃碰杠的牌、吃碰杠的来源"""
    index = None
    draw = None
    i = 0
    meld = []
    while i < len(string):
        if "0" <= string[i] <= "9":
            tile = parse_tenhou_tile(int(string[i : i + 2]))
            meld.append(tile)
            if draw == "":
                draw = tile
            i += 2
        else:
            index = i // 2
            i += 1
            draw = ""
    return meld, draw, index


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


@dataclass
class TenhouRoundPlayerStatus(Deserializable):
    """一个玩家相关的牌"""

    dealer: int
    """庄家座次"""

    seat: int
    """本家座次"""

    hand: List[str]
    """手中的牌"""

    meld: List[List[str]] = field(default_factory=list)
    """副露面子、刻子以及暗杠"""

    river: List[str] = field(default_factory=list)
    """牌河，包括被吃碰杠的牌"""

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

    def ankan(self, draw: str, tiles: List[str]):
        """模拟暗杠"""
        self.hand.append(draw)
        for t in tiles:
            self._remove_from_hand(t)
        self.meld.append(tiles)

    def chakan(self, draw: str):
        """模拟加杠"""
        # 寻找对应的碰牌，并在横牌的前面插入
        for m in self.meld:
            if m[0].lower().replace("0", "5") == draw.lower().replace("0", "5"):
                for i in range(3):
                    if m[i][1] in "MPSZ":
                        m.insert(i, draw.upper())
                        break
                break

    def daiminkan(self, draw: str, tiles: List[str], distance: int):
        """模拟大明杠"""
        self.hand.append(draw)
        for t in tiles:
            self._remove_from_hand(t)
        meld = tiles.copy()
        meld[distance] = meld[distance].upper()
        self.meld.append(meld)

    def chi(self, draw: str, tiles: List[str]):
        """模拟吃"""
        self.pon(draw, tiles, 0)

    def pon(self, draw: str, tiles: List[str], distance: int):
        """模拟碰"""
        self.hand.append(draw)
        for t in tiles:
            self._remove_from_hand(t)
        meld = tiles.copy()
        meld[distance] = meld[distance].upper()
        self.meld.append(meld)

    @property
    def status(self) -> Tuple[List[str], List[List[str]]]:
        """返回：暗牌、明牌"""
        return sorted_tiles(self.hand), self.meld


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

    agari: Optional[str]
    """最后一张打出/自摸的牌，如果有和牌则会成为 Agari"""

    player_final_status: List[TenhouRoundPlayerStatus]
    """玩家最后的状态（包括手牌、副露、牌河）"""

    @staticmethod
    def from_json(obj) -> RoundFullInfo:
        round_number, honba, kyoutaku = obj[0]
        wind = round_number // 4
        dealer = round_number % 4
        initial_points = obj[1]
        dora = [parse_tenhou_tile(v) for v in obj[2]]
        uradora = [parse_tenhou_tile(v) for v in obj[3]]
        initial_hands = [[parse_tenhou_tile(v) for v in l] for l in obj[4:16:3]]
        players = [
            TenhouRoundPlayerStatus(dealer, i, initial_hands[i]) for i in range(4)
        ]
        riichi_status = [False] * 4

        # 开始模拟牌局
        # 摸的牌
        draws: List[List[Union[int, str]]] = obj[5:16:3]
        # 切的牌
        discards: List[List[Union[int, str]]] = obj[6:16:3]
        # 目前每玩家已进行的巡数
        indices = [0] * 4
        # 当前玩家
        current = dealer
        # 如果接下来 3 要碰 1，则加入 (1, 3)
        order_jumps = []
        # 和牌（最后一张打出的牌，或最后一个自摸的牌）注：不判断是否和牌
        agari: Optional[str] = None

        # 检查第一轮有没有人吃碰杠准备
        for p in range(4):
            if indices[p] < len(draws[p]) and isinstance(draws[p][indices[p]], str):
                _, _, distance = parse_tenhou_meld(draws[p][indices[p]])
                order_jumps.append(((p - 1 - distance) % 4, p))

        while indices[current] < len(draws[current]):
            draw = draws[current][indices[current]]
            if indices[current] == len(discards[current]):
                # 自摸
                agari = parse_tenhou_tile(draw)
                break
            discard = discards[current][indices[current]]
            indices[current] += 1
            # 暗杠：特殊处理
            if isinstance(discard, str) and "a" in discard:
                draw_tile = parse_tenhou_tile(draw)
                players[current].ankan(
                    draw_tile,
                    parse_tenhou_meld(discard)[0],
                )
                agari = draw_tile
                continue
            # 加杠：特殊处理
            if isinstance(discard, str) and "k" in discard:
                draw_tile = parse_tenhou_tile(draw)
                players[current].chakan(draw_tile)
                agari = draw_tile
                continue
            # 此时如果切牌是 str，必为立直
            if isinstance(discard, str):
                assert discard[0] == "r"
                discard = int(discard[1:])
                riichi_status[current] = True
            # 吃碰杠
            if isinstance(draw, str):
                meld, draw_tile, distance = parse_tenhou_meld(draw)
                # 大明杠跳到下一步
                if "m" in draw:
                    players[current].daiminkan(draw_tile, meld, distance)
                    continue
                discard_tile = parse_tenhou_tile(discard)
                agari = discard_tile
                if "c" in draw:
                    players[current].chi(draw_tile, meld)
                    players[current].discard(discard_tile)
                elif "p" in draw:
                    players[current].pon(draw_tile, meld, distance)
                    players[current].discard(discard_tile)
                else:
                    raise RoundSimulationFailure()
            else:
                draw_tile = parse_tenhou_tile(draw)
                if discard == 60:
                    # 摸切
                    discard_tile = draw_tile
                else:
                    # 手切
                    discard_tile = parse_tenhou_tile(discard)
                agari = discard_tile
                players[current].draw_and_discard(draw_tile, discard_tile)
            # 检查此家打出的牌有没有被吃碰杠
            if indices[current] < len(draws[current]) and isinstance(
                draws[current][indices[current]], str
            ):
                _, _, distance = parse_tenhou_meld(draws[current][indices[current]])
                order_jumps.append(((current - 1 - distance) % 4, current))
            # 跳转到下一个玩家
            for i in range(len(order_jumps)):
                if current == order_jumps[i][0]:
                    current = order_jumps[i][1]
                    order_jumps.pop(i)
                    break
            else:
                current = (current + 1) % 4

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
            agari=agari,
            player_final_status=players,
        )
