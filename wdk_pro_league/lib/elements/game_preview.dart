import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '../game_view.dart';
import '../io/game_data.dart';
import 'basic.dart';
import 'card.dart';
import 'page.dart';

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
    final scheme = Theme.of(context).colorScheme;
    if (point < 0) {
      return scheme.error;
    } else if (point < 12500) {
      return Color.alphaBlend(
          Colors.grey.shade500.withAlpha(192), scheme.error);
    } else if (point <= 25000) {
      return Colors.grey.shade600;
    } else if (point <= 50000) {
      return Color.alphaBlend(
          Colors.grey.shade500.withAlpha(64), scheme.primary);
    } else {
      return scheme.primary;
    }
  }

  /// 根据不同的名次使用不同颜色
  Color _colorFromOrder(int order, {int point = 10}) {
    final scheme = Theme.of(context).colorScheme;
    if (point < 0 && order == 3) {
      return scheme.error;
    } else if (order == 3) {
      return Color.alphaBlend(
          Colors.grey.shade500.withAlpha(192), scheme.error);
    } else if (order == 2) {
      return Colors.grey.shade500;
    } else if (order == 1) {
      return Color.alphaBlend(
          Colors.grey.shade500.withAlpha(168), scheme.primary);
    } else {
      return scheme.primary;
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
      spacing: 8,
      children: [
        buildSeat(context, seat),
        buildPlayerName(context, player.playerName, player.currentDan),
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
              color: _colorFromOrder(
                game.orderedPlayerIds.indexOf(player.playerId),
                point: game.playerPoints[seat],
              ).withAlpha(48),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          nameDisplay,
          pointDisplay,
          resultDisplay,
        ],
      ).padding(all: 4),
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
  Widget? buildHint(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.data.gameType,
          ),
          Text(
            formatDate(widget.data.date, [
              yyyy,
              "-",
              mm,
              "-",
              dd,
              " ",
              HH,
              ':',
              nn,
            ]),
          ),
        ],
      );

  /// 卡片内侧不添加 padding
  @override
  Widget addPadding(Widget content) => content;

  /// 点击查看游戏详情
  @override
  void onTap(BuildContext context) {
    Future.delayed(const Duration()).then((a) {
      Navigator.of(context)
          .push(loadPage(GameViewPage(gameId: widget.data.gameId)));
    });
  }
}
