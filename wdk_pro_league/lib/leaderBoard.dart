import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:wdk_pro_league/elements/rank.dart';
// import 'elements/rank.dart';

part 'leaderBoard.g.dart';

/// Public info for players
@JsonSerializable()
class LeaderBoardPlayerInfo {
  /// Player name (unique)
  final String name;

  /// Player total pt
  final int pt;

  /// Player R points
  final double r;

  /// Player rank (1-10)
  final int rank;

  /// Number of games played
  final int gameCount;

  /// Number of games won
  final int winCount;

  LeaderBoardPlayerInfo(
      this.name, this.pt, this.r, this.rank, this.gameCount, this.winCount);

  factory LeaderBoardPlayerInfo.fromJson(Map<String, dynamic> json) =>
      _$LeaderBoardPlayerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderBoardPlayerInfoToJson(this);
}

/// Data for the leader board
@JsonSerializable()
class LeaderBoardData {
  /// Player data
  final List<LeaderBoardPlayerInfo> playerInfoList;

  /// Time of last update
  final DateTime updateTime;

  LeaderBoardData(this.playerInfoList, this.updateTime);

  factory LeaderBoardData.fromJson(Map<String, dynamic> json) =>
      _$LeaderBoardDataFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderBoardDataToJson(this);
}

final sampleData = LeaderBoardData([
  LeaderBoardPlayerInfo("Alice", 1000, 1500, 4, 97, 51),
  LeaderBoardPlayerInfo("Bob", 800, 1500, 3, 100, 40),
  LeaderBoardPlayerInfo("Charles", 1200, 1500, 5, 100, 60),
  LeaderBoardPlayerInfo("David", 10000, 1300, 4, 100, 49),
  LeaderBoardPlayerInfo("Alice", 1000, 1500, 4, 100, 50),
  LeaderBoardPlayerInfo("Bob", 800, 1500, 3, 100, 40),
  LeaderBoardPlayerInfo("Charles", 1200, 1500, 5, 100, 60),
  LeaderBoardPlayerInfo("David", 10000, 1300, 4, 100, 49),
  LeaderBoardPlayerInfo("Alice", 1000, 1500, 4, 100, 50),
  LeaderBoardPlayerInfo("Bob", 800, 1500, 3, 100, 40),
  LeaderBoardPlayerInfo("Charles", 1200, 1500, 5, 100, 60),
  LeaderBoardPlayerInfo("David", 10000, 1300, 4, 100, 49),
], DateTime.now());

/// Leader Board Page
///
/// All data should be ready
class LeaderBoardPage extends StatelessWidget {
  const LeaderBoardPage({super.key, this.data});

  final LeaderBoardData? data;

  @override
  Widget build(BuildContext context) {
    // highest ranking players first
    var displayData = data ?? sampleData;
    displayData.playerInfoList.sort(
      (a, b) => b.pt.compareTo(a.pt),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: displayData.playerInfoList
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
  final LeaderBoardPlayerInfo info;

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
          shadowColor: Color(0x30000000),
        ) // shadow borderRadius
        .constrained(height: 80)
        .padding(horizontal: 12, vertical: 6) // margin
        .gestures(
          onTapChange: (tapStatus) => setState(() => pressed = tapStatus),
          onTapDown: (details) => print('tapDown'),
          onTap: () => print('onTap'),
        )
        .scale(all: pressed ? 0.97 : 1.0, animate: true)
        .animate(Duration(milliseconds: 150), Curves.easeOut);

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
        widget.info.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ).padding(right: 8),
      buildRankText(context, widget.info.rank),
    ]).padding(bottom: 5);

    final String winRateText;
    if (widget.info.gameCount == 0) {
      winRateText = '暂无数据';
    } else {
      winRateText =
          '${(widget.info.winCount / widget.info.gameCount * 100).round()}%';
    }
    final Widget description = Text(
      '${widget.info.pt}pt'
      '  '
      '胜率: $winRateText'
      '  '
      'R: ${widget.info.r.round()}',
      style: const TextStyle(
        color: Colors.black26,
        fontWeight: FontWeight.normal,
        fontSize: 12,
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
