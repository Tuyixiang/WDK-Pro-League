import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:wdk_pro_league/elements/basic.dart';
import 'package:wdk_pro_league/elements/card.dart';
import 'package:wdk_pro_league/io/game_data.dart';

import '../io/player_data.dart';
import '../io/round_data.dart';

/// 用卡片呈现一局的情况
///
/// 对于多家和牌的情况会呈现为多张卡牌
class RoundResultView extends StatelessWidget {
  final GameData gameData;
  final RoundData roundData;

  /// 是否按照得分排名进行排序
  final bool sortByOrder;

  /// 将指定玩家进行高亮
  final String? highlightPlayerId;

  const RoundResultView({
    super.key,
    required this.gameData,
    required this.roundData,
    this.sortByOrder = false,
    this.highlightPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    // 绘制场信息
    final roundInfo =
        "${windNames[roundData.wind]}${numberNames[roundData.dealer]}局"
        "  "
        "${roundData.honba}本场";
    final hint = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Text(roundInfo)],
    );

    if (roundData.ending == "和" || roundData.ending == "自摸") {
      return roundData.wins
          .mapIndexed((index, win) => RoundResultCard(
                players: gameData.players,
                initialPoints: roundData.initialPoints,
                resultPoints: roundData.resultPoints[index],
                dealer: roundData.dealer,
                ending: roundData.ending,
                win: win,
                hint: index == 0 ? hint : null,
              ))
          .toList()
          .toColumn();
    } else {
      return RoundResultCard(
        players: gameData.players,
        initialPoints: roundData.initialPoints,
        resultPoints: roundData.resultPoints[0],
        dealer: roundData.dealer,
        ending: roundData.ending,
        hint: hint,
      );
    }
  }
}

class RoundResultCard extends StatefulWidget {
  final List<PlayerPreview> players;
  final List<int> initialPoints;
  final List<int> resultPoints;
  final int dealer;
  final String ending;
  final Win? win;

  /// 如果是第一个卡牌，上方的提示文字
  final Widget? hint;

  const RoundResultCard({
    super.key,
    required this.players,
    required this.initialPoints,
    required this.resultPoints,
    required this.dealer,
    required this.ending,
    this.win,
    this.hint,
  });

  @override
  State<StatefulWidget> createState() => _RoundResultCardState();
}

class _RoundResultCardState extends CardState<RoundResultCard> {
  @override
  Widget buildChild(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              _buildPlayerList(context),
              const SizedBox(height: 8),
              Row(children: [_buildWin(context)]).constrained(maxWidth: 400),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayerList(context),
              _buildWin(context),
            ],
          );
        }
      });

  /// 绘制一局游戏中得分/失分的数字
  Widget _buildPointDelta(BuildContext context, int delta) {
    // 不显示 0
    if (delta == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyLarge!;
    final text = delta > 0 ? "+$delta" : delta.toString();

    // 役满反色
    if (delta >= 32000) {
      return Text(
        text,
        style: defaultStyle.copyWith(
          color: theme.canvasColor,
          fontWeight: FontWeight.bold,
        ),
      ).invertWithColor(theme.primaryColor);
    }

    final TextStyle style;
    if (delta >= 8000) {
      style = defaultStyle.copyWith(
        color: theme.primaryColor,
        fontWeight: FontWeight.bold,
      );
    } else if (delta > 0) {
      style = defaultStyle.copyWith(
        color: theme.colorScheme.onBackground,
      );
    } else if (delta > -8000) {
      style = defaultStyle.copyWith(
        color: theme.disabledColor,
      );
    } else {
      style = defaultStyle.copyWith(
        color: theme.colorScheme.error,
        fontWeight: FontWeight.bold,
      );
    }

    return Text(
      text,
      style: style,
    );
  }

  /// 绘制玩家及得分
  Widget _buildPlayerList(BuildContext context) => Table(
        border: null,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(24),
          1: FlexColumnWidth(2),
        },
        children: List.generate(
          4,
          (seat) => TableRow(
            children: [
              // 座位（当前自风）
              buildSeat(
                context,
                (seat - widget.dealer) % 4,
                highlight: (seat == widget.dealer),
              ).center(),
              // 玩家名及段位
              buildPlayerName(
                context,
                widget.players[seat].playerName,
                widget.players[seat].currentDan,
              ).center(),
              // 初始分数
              Text(
                widget.initialPoints[seat].toString(),
                style: Theme.of(context).textTheme.bodyLarge,
              ).center(),
              // 得分
              _buildPointDelta(
                context,
                widget.resultPoints[seat],
              ).center(),
            ],
          ),
        ),
      ).constrained(maxWidth: 400);

  /// 绘制结束类型
  Widget _buildEnding(BuildContext context) {
    if (widget.ending != "和" && widget.ending != "自摸") {
      return Text(widget.ending, style: Theme.of(context).textTheme.titleMedium)
          .bold()
          .invertWithColor(Colors.grey.shade300, foreground: Colors.black);
    }
    return Text(widget.ending, style: Theme.of(context).textTheme.titleMedium)
        .bold()
        .invertWithColor(Theme.of(context).primaryColorLight,
            foreground: Colors.black);
  }

  /// 绘制和牌大小（如“3番30符”）
  Widget _buildWinTitle(BuildContext context) {
    if (widget.ending != "和" && widget.ending != "自摸") {
      return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildEnding(context),
          ]);
    }
    final han = widget.win!.han;
    final fu = widget.win!.fu;
    final yakuman = widget.win!.yakuman;
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium;
    final Widget winText;
    if (yakuman >= 2) {
      winText = Text("${numberNames[yakuman - 1]}倍役满", style: style)
          .bold()
          .invertWithColor(theme.primaryColorLight,
              foreground: theme.primaryColor);
    } else if (yakuman > 0) {
      winText = Text("役满", style: style).bold().invertWithColor(
          theme.primaryColorLight,
          foreground: theme.primaryColor);
    } else if (han >= 12) {
      winText = Text("三倍满", style: style).bold().textColor(theme.primaryColor);
    } else if (han >= 8) {
      winText = Text("倍满", style: style).bold().textColor(theme.primaryColor);
    } else if (han >= 6) {
      winText = Text("跳满", style: style).bold().textColor(theme.primaryColor);
    } else if ((han >= 4 && fu >= 30) || (han >= 3 && fu >= 60)) {
      winText = Text("满贯", style: style).bold();
    } else {
      winText = Text("$han番$fu符", style: style);
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          winText,
          const SizedBox(width: 16),
          _buildEnding(context),
        ]);
  }

  /// 绘制役种
  Widget _buildYaku(BuildContext context, String name, int han) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: style),
        const SizedBox(width: 1, height: 20)
            .backgroundColor(Colors.white)
            .padding(horizontal: 4),
        Text(han.toString(), style: style).bold(),
      ],
    )
        .padding(horizontal: 6)
        .backgroundColor(Colors.grey.shade300)
        .clipRRect(all: 25)
        .padding(bottom: 8);
  }

  /// 绘制和牌信息
  Widget _buildWin(BuildContext context) {
    if (widget.ending != "和" && widget.ending != "自摸") {
      return Column(
        children: [
          _buildWinTitle(context),
        ],
      ).expanded();
    }
    return Column(
      children: [
        _buildWinTitle(context),
        const Divider(),
        Wrap(
          spacing: 16,
          children: widget.win!.yaku
              .map((item) => _buildYaku(context, item.$1, item.$2))
              .toList(),
        )
      ],
    ).expanded();
  }

  @override
  Widget? buildHint(BuildContext context) => widget.hint;
}
