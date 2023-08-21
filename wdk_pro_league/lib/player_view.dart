import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:wdk_pro_league/elements/page.dart';
import 'package:wdk_pro_league/io/player_data.dart';

import 'elements/game_preview.dart';
import 'elements/loading.dart';
import 'io/io.dart';

class PlayerViewPage extends StatefulWidget {
  final String playerId;

  const PlayerViewPage({super.key, required this.playerId});

  State<PlayerViewPage> createState() => _PlayerViewPageState();
}

class _PlayerViewPageState extends State<PlayerViewPage> {
  PlayerData? data;
  bool initialized = false;
  bool sortByOrder = true;

  @override
  void initState() {
    super.initState();
    data = IO.cachedPlayerData[widget.playerId];
    initialized = data != null;
    print("PVP init with data $data");
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      print("Start initializing player page");
      initialized = true;
      Provider.of<Loading>(context)
          .on(() => IO.getPlayerData(widget.playerId))
          .then((data) {
        print("Player page data fetched");
        setState(() {
          this.data = data;
        });
      });
    }

    final Widget body;

    if (data == null) {
      body = const SizedBox.shrink();
    } else {
      final gameList = data!.gameHistory;
      body = Column(
        children: [
          _buildPlayerStat(),
          ListView.builder(
            itemCount: gameList.length,
            itemBuilder: (context, index) => GamePreviewCard(
              data: gameList[gameList.length - index - 1],
              sortByOrder: sortByOrder,
              highlightPlayerId: data!.playerId,
            ),
          ).expanded(),
        ],
      );
    }
    return Scaffold(
      appBar: buildAppBar(
        context: context,
        title: "游戏历史",
        actions: [
          IconButton(
            onPressed: toggleSortByOrder,
            icon: Icon(sortByOrder
                ? Icons.format_list_bulleted
                : Icons.format_list_numbered),
          ),
        ],
      ),
      // 为每个游戏记录生成卡片（倒序）
      body: body,
    );
  }

  /// 绘制玩家统计数据
  Widget _buildPlayerStat() {
    // TODO
    return const SizedBox.shrink();
  }

  /// 切换每个游戏按座次排序或按排名排序
  void toggleSortByOrder() {
    setState(() {
      sortByOrder = !sortByOrder;
    });
  }
}
