from datetime import datetime
from pprint import pprint
import random
from game_data import *
from uuid import uuid4

from main import app
from flask import Flask
from api import *
from tqdm import tqdm

for _ in range(40):
    players = random.sample(list(player_database.all_player_data.values()), k=4)

    points = [int(random.normalvariate(250, 100)) * 100 for _ in range(3)]
    points.append(100000 - sum(points))
    random.shuffle(points)
    gd = GameData(
        players=[p.snapshot for p in players],
        player_points=points,
    )

    game_controller.apply_game(gd)
    gd.print_log()

# pprint(game_database)
# pprint(player_database)
game_database.save()
player_database.save()
