import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wdk_pro_league/elements/game_preview.dart';

import 'elements/loading.dart';
import 'elements/page.dart';
import 'elements/round_view.dart';
import 'io/game_data.dart';
import 'io/io.dart';

class GameViewPage extends StatefulWidget {
  final String gameId;

  const GameViewPage({super.key, required this.gameId});

  @override
  State<StatefulWidget> createState() => _GameViewPageState();
}

class _GameViewPageState extends State<GameViewPage> {
  GameData? data;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    data = IO.cachedGameData[widget.gameId];
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      print("Start fetching game data for ${widget.gameId}");
      initialized = true;
      Provider.of<Loading>(context)
          .on(() => IO.getGameData(widget.gameId))
          .then((data) {
        print("Game data fetched for ${widget.gameId}");
        setState(() {
          this.data = data;
        });
      });
    }

    final body = data == null
        ? const SizedBox.shrink()
        : ListView.builder(
            itemCount: data!.rounds.length + 1,
            itemBuilder: (context, index) {
              if (index == data!.rounds.length) {
                return GamePreviewCard(data: data!.preview);
              }
              return RoundResultView(
                  gameData: data!, roundData: data!.rounds[index]);
            },
          );

    return Scaffold(
      appBar: buildAppBar(context: context, title: "游戏详情"),
      body: body,
    );
  }
}
