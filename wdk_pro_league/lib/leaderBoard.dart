import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:wdk_pro_league/elements/appBar.dart';
import 'package:wdk_pro_league/elements/rank.dart';
import 'package:wdk_pro_league/io.dart';

import 'elements/globalState.dart';
// import 'elements/rank.dart';

/// Leader Board Page
class LeaderBoardPage extends MyPage {
  @override
  String get title {
    return "WDK Pro League 排行榜";
  }

  const LeaderBoardPage({super.key});

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  List<PlayerPreview> data = [];
  bool initialized = false;

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      print("Start initializing leader board");
      initialized = true;
      Provider.of<Loading>(context).on(IO.getLeaderBoard).then((data) {
        setState(() {
          print("Leader board data fetched");
          this.data = data;
        });
      });
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: data
          .mapIndexed(
            (index, info) => PlayerCard(index: index, info: info),
          )
          .toList(),
    ).scrollable();
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

class _PlayerCardState extends State<PlayerCard> {
  bool pressed = false;

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
  Widget build(BuildContext context) {
    cardItem({required Widget child}) => Styled.widget(child: child)
        .alignment(Alignment.center)
        .borderRadius(all: 15)
        .ripple()
        .backgroundColor(Colors.white, animate: true)
        .clipRRect(all: 25) // clip ripple
        .borderRadius(all: 25, animate: true)
        .elevation(
          pressed ? 0 : 20,
          borderRadius: BorderRadius.circular(25),
          shadowColor: const Color(0x30000000),
        ) // shadow borderRadius
        .constrained(height: 80)
        .padding(horizontal: 12, vertical: 6) // margin
        .gestures(
          onTapChange: (tapStatus) => setState(() => pressed = tapStatus),
          onTapDown: (details) => print('tapDown'),
          onTap: () => print('onTap'),
        )
        .scale(all: pressed ? 0.97 : 1.0, animate: true)
        .animate(const Duration(milliseconds: 150), Curves.easeOut);

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
      buildRankText(context, widget.info.currentDan),
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

    return cardItem(
      child: <Widget>[
        index,
        <Widget>[
          name,
          description,
        ].toColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ].toRow(),
    );
  }
}
