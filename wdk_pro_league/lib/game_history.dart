import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wdk_pro_league/elements/page.dart';

import 'elements/game_preview.dart';
import 'elements/loading.dart';
import 'io/game_data.dart';
import 'io/io.dart';

class GameHistoryPage extends StatefulWidget {
  const GameHistoryPage({super.key});

  State<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends State<GameHistoryPage> {
  List<GamePreview>? data;

  bool sortByOrder = false;

  _GameHistoryPageState() : data = IO.cachedGameHistory;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      print("Start initializing game history");
      data = [];
      Provider.of<Loading>(context).on(IO.getGameHistory).then((data) {
        print("Game history data fetched");
        setState(() {
          this.data = data;
        });
      });
    }
    return buildPage(
      context: context,
      title: "游戏历史",
      // 按钮来切换是否根据名次排序
      actions: [
        IconButton(
          onPressed: toggleSortByOrder,
          icon: Icon(sortByOrder
              ? Icons.format_list_bulleted
              : Icons.format_list_numbered),
        )
      ],
      // 为每个游戏记录生成卡片（倒序）
      body: ListView.builder(
        itemCount: data!.length,
        itemBuilder: (context, index) => GamePreviewCard(
            data: data![data!.length - index - 1], sortByOrder: sortByOrder),
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
