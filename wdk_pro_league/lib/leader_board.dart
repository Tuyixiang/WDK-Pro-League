import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:wdk_pro_league/elements/card.dart';
import 'package:wdk_pro_league/game_history.dart';

import 'io.dart';
import 'elements/rank.dart';
import 'elements/loading.dart';

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
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("WDK Pro League 排行榜",
                  style: TextStyle(fontWeight: FontWeight.bold))
              .center(),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(_loadHistoryPage());
              },
              icon: const Icon(Icons.history),
            )
          ],
        ),
        body: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) =>
              PlayerCard(index: index, info: data[index]),
        ));
  }

  /// 加载历史页面
  Route _loadHistoryPage() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          GameHistoryPage(),
      // 从下至上弹出的动画
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
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
  _PlayerCardState createState() => _PlayerCardState();
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
    final Widget index = Styled.widget(
      child: Text(
        (widget.index + 1).toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 36,
        ),
      ),
    )
        .center()
        .card(shape: const CircleBorder(), color: colorFromIndex(widget.index))
        .width(60)
        .padding(horizontal: 8);

    final Widget name = Row(children: [
      Text(
        widget.info.playerName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ).padding(right: 8),
      buildDan(context, widget.info.currentDan),
    ]).padding(bottom: 5);

    final String orderText;
    if (widget.info.gameCount == 0) {
      orderText = '暂无数据';
    } else {
      orderText = widget.info.orderCount.join("/");
    }
    final Widget description = Text(
      'pt: ${widget.info.currentPt}/${widget.info.thresholdPt}'
      '  '
      '顺位场次: $orderText'
      '  '
      'R: ${widget.info.rValue.round()}',
      style: const TextStyle(
        color: Colors.black26,
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
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
}
