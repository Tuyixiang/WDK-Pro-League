import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:wdk_pro_league/elements/card.dart';
import 'package:wdk_pro_league/elements/page.dart';
import 'package:wdk_pro_league/game_history.dart';
import 'package:wdk_pro_league/player_view.dart';

import 'elements/basic.dart';
import 'elements/loading.dart';
import 'io/io.dart';
import 'io/player_data.dart';

/// Leader Board Page
class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({super.key});

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  List<PlayerPreview> data = [];
  bool initialized = false;

  _LeaderBoardPageState() {
    if (IO.cachedLeaderBoard != null) {
      data = IO.cachedLeaderBoard!;
      initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      print("Start initializing leader board");
      initialized = true;
      Provider.of<Loading>(context).on(IO.getLeaderBoard).then((data) {
        print("Leader board data fetched");
        setState(() {
          this.data = data;
        });
      });
    }
    return buildPage(
      context: context,
      title: "WDK Pro League 排行榜",
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(loadPage(const GameHistoryPage()));
          },
          icon: const Icon(Icons.history),
        )
      ],
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) =>
            PlayerCard(index: index, info: data[index]),
      ),
    );
  }
}

/// Card displaying each player
class PlayerCard extends StatefulWidget {
  /// Index in list (first place is 0)
  final int index;
  final PlayerPreview info;

  const PlayerCard({super.key, required this.index, required this.info});

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends CardState<PlayerCard> {
  Color colorFromIndex(i) {
    final themeColor = Theme.of(context).primaryColor;
    if (i == 0) {
      return themeColor;
    } else if (i == 1) {
      return Color.alphaBlend(Colors.white30, themeColor);
    } else if (i == 2) {
      return Color.alphaBlend(Colors.white60, themeColor);
    } else {
      return Colors.grey.shade300;
    }
  }

  @override
  Widget buildChild(BuildContext context) {
    final Widget index = Text(
      (widget.index + 1).toString(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 36,
      ),
    )
        .center()
        .card(shape: const CircleBorder(), color: colorFromIndex(widget.index))
        .width(60)
        .padding(right: 8);

    final Widget name =
        buildPlayerName(context, widget.info.playerName, widget.info.currentDan)
            .padding(bottom: 5);

    final String orderText;
    if (widget.info.gameCount == 0) {
      orderText = '暂无数据';
    } else {
      orderText = widget.info.orderCount.join("/");
    }
    final descriptionStyle = TextStyle(
      color: Theme.of(context).disabledColor,
      fontSize: 14,
    );
    final description = Wrap(
      alignment: WrapAlignment.start,
      spacing: 12,
      children: [
        Text(
          'pt: ${widget.info.currentPt}/${widget.info.thresholdPt}',
          style: descriptionStyle,
        ),
        Text(
          '战绩: $orderText',
          style: descriptionStyle,
        ),
        Text(
          'R: ${widget.info.rValue.round()}',
          style: descriptionStyle,
        ),
      ],
    );

    return Row(children: [
      index,
      Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            name,
            description,
          ]),
    ]);
  }

  /// 点击时展开玩家详情页面
  @override
  void onTap(BuildContext context) {
    Future.delayed(const Duration()).then((a) {
      Navigator.of(context)
          .push(loadPage(PlayerViewPage(playerId: widget.info.playerId)));
    });
  }
}
