import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '../io/game_data.dart';
import 'card.dart';
import 'rank.dart';

class GamePreviewCard extends StatefulWidget {
  final GamePreview data;

  /// 是否按照得分排名进行排序
  final bool sortByOrder;

  /// 将指定玩家进行高亮
  final String? highlightPlayerId;

  const GamePreviewCard({
    super.key,
    required this.data,
    this.sortByOrder = false,
    this.highlightPlayerId,
  });

  @override
  State<GamePreviewCard> createState() => _GamePreviewCardState();
}

class _GamePreviewCardState extends CardState<GamePreviewCard> {
  @override
  double? get height {
    return null;
  }

  /// 根据不同的得分使用不同颜色
  Color _colorFromPoint(int point) {
    final themeColor = Theme.of(context).primaryColor;
    if (point < 0) {
      return Colors.deepOrangeAccent;
    } else if (point < 12500) {
      return Color.alphaBlend(
          Colors.grey.shade500.withAlpha(192), Colors.deepOrangeAccent);
    } else if (point <= 25000) {
      return Colors.grey.shade600;
    } else if (point <= 50000) {
      return Color.alphaBlend(Colors.grey.shade500.withAlpha(64), themeColor);
    } else {
      return themeColor;
    }
  }

  /// 将 +- 分数转换为字符串
  String _formatDelta(num value) {
    final v = value.toInt();
    if (v >= 0) {
      return "+$v";
    }
    return v.toString();
  }

  Widget _buildPlayer(BuildContext context, GamePreview game, int seat) {
    final player = game.players[seat];

    // 座次、玩家名、玩家段位，优先在座次后面换行
    final nameDisplay = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          ["东", "南", "西", "北"][seat],
          style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
        ),
        Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                player.playerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ).padding(horizontal: 8),
              buildDan(context, player.currentDan),
            ]),
      ],
    );

    final pointColor = _colorFromPoint(game.playerPoints[seat]);
    final pointDisplay = Text(
      game.playerPoints[seat].toString(),
      style: TextStyle(
        letterSpacing: -0.5,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: pointColor,
      ),
    ).center();

    final resultStyle = TextStyle(
      fontSize: 14,
      color: Theme.of(context).disabledColor,
    );
    final resultDisplay = Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 8,
      children: [
        Text(
          "${_formatDelta(game.ptDelta[seat])}pt",
          style: resultStyle,
        ),
        Text(
          "${_formatDelta(game.rDelta[seat])}R",
          style: resultStyle,
        ),
      ],
    );

    final isHighlightedPlayer = player.playerId == widget.highlightPlayerId;
    return Container(
      decoration: isHighlightedPlayer
          ? BoxDecoration(
              gradient: RadialGradient(
                stops: const [0, 0.5, 0.75],
                colors: [
                  pointColor.withAlpha(64),
                  pointColor.withAlpha(32),
                  pointColor.withAlpha(0),
                ],
              ),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          nameDisplay,
          pointDisplay,
          resultDisplay,
        ],
      ),
    ).expanded();
  }

  /// 在卡片内绘制所有玩家的得分情况
  @override
  Widget buildChild(BuildContext context) {
    final List<int> order;
    if (widget.sortByOrder) {
      order = widget.data.orderedPlayerIds
          .map(
            (playerId) => widget.data.players.indexWhere(
              (player) => player.playerId == playerId,
            ),
          )
          .toList();
    } else {
      order = List.generate(4, (i) => i);
    }
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children:
            order.map((i) => _buildPlayer(context, widget.data, i)).toList());
  }

  /// 在卡片外标注游戏信息
  @override
  Widget buildWrapper(BuildContext context, Widget card) {
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.data.gameType,
          style: TextStyle(
            color: Theme.of(context).disabledColor,
          ),
        ),
        Text(
          widget.data.date.toLocal().toString(),
          style: TextStyle(
            color: Theme.of(context).disabledColor,
          ),
        ),
      ],
    ).constrained(maxWidth: maxWidth).padding(horizontal: 16, top: 8);
    return Column(children: [header, card]);
  }
}
