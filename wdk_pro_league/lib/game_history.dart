import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import 'elements/game_preview.dart';
import 'elements/loading.dart';
import 'io/game_data.dart';
import 'io/io.dart';

class GameHistoryPage extends StatefulWidget {
  const GameHistoryPage({super.key});

  State<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends State<GameHistoryPage> {
  List<GamePreview> data = [];
  bool initialized = false;

  bool sortByOrder = false;

  _GameHistoryPageState() {
    if (IO.cachedGameHistory != null) {
      data = IO.cachedGameHistory!;
      initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      print("Start initializing game history");
      initialized = true;
      Provider.of<Loading>(context).on(IO.getGameHistory).then((data) {
        print("Game history data fetched");
        setState(() {
          this.data = data;
        });
      });
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("游戏历史", style: TextStyle(fontWeight: FontWeight.bold))
            .center(),
        actions: [
          IconButton(
            onPressed: toggleSortByOrder,
            icon: Icon(sortByOrder
                ? Icons.format_list_bulleted
                : Icons.format_list_numbered),
          )
        ],
      ),
      // 为每个游戏记录生成卡片（倒序）
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) => GamePreviewCard(
            data: data[data.length - index - 1], sortByOrder: sortByOrder),
      ),
    );
  }

  /// 切换每个游戏按座次排序或按排名排序
  void toggleSortByOrder() {
    setState(() {
      sortByOrder = !sortByOrder;
    });
  }
}
