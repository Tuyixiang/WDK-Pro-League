import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:wdk_pro_league/elements/basic.dart';
import 'package:wdk_pro_league/elements/card.dart';
import 'package:wdk_pro_league/io/game_data.dart';

import '../io/round_data.dart';

/// 折线图展示玩家得分走势
class GamePlot extends StatefulWidget {
  final GameData data;

  const GamePlot({super.key, required this.data});

  @override
  State<StatefulWidget> createState() => _GamePlotState();
}

class _GamePlotState extends CardState<GamePlot> {
  /// 卡片内侧的 padding
  @override
  Widget addPadding(Widget content) {
    return content.padding(horizontal: 12, top: 8);
  }

  @override
  Widget buildChild(BuildContext context) {
    // 按照名次排序的颜色
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Color.alphaBlend(
        Colors.white.withAlpha(96),
        Theme.of(context).colorScheme.secondary,
      ),
      Theme.of(context).colorScheme.error,
    ];
    final orderedSeats = widget.data.orderedPlayerSeats;
    final playerOrder = widget.data.playerOrder;
    // 生成绘图所用数据
    final encountered = <String>{};
    final data = widget.data.rounds.mapIndexed((index, round) {
      var roundName = formatRound(round);
      if (encountered.contains(roundName)) {
        roundName = "#$index";
      } else {
        encountered.add(roundName);
      }
      return round.initialPoints.map((point) => (point, roundName)).toList();
    }).followedBy([
      widget.data.rounds.last.finalPoints.map((point) => (point, "#-")).toList()
    ]).toList();
    final points = widget.data.rounds.expand((round) => round.finalPoints);
    final minPoint = points.min;
    final maxPoint = points.max;
    return SfCartesianChart(
      legend: Legend(
          isVisible: true,
          toggleSeriesVisibility: false,
          // 图例：绘制玩家名称
          legendItemBuilder: (name, series, point, index) {
            final player = widget.data.players[orderedSeats[index]];
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                buildSeat(context, index),
                Text(
                  player.playerName,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors[index],
                      ),
                ),
                buildDan(context, player.currentDan),
              ],
            );
          }),
      series: List.generate(
          4,
          (player) => LineSeries<List<(int, String)>, dynamic>(
                dataSource: data,
                xValueMapper: (round, index) => round[player].$2,
                yValueMapper: (round, index) => round[player].$1,
                color: colors[playerOrder[player]],
                width: 4,
                markerSettings: MarkerSettings(
                  isVisible: true,
                  color: colors[playerOrder[player]],
                ),
                onPointTap: (_) {},
              )),
      // 不显示多次相同局名
      primaryXAxis: CategoryAxis(
        // arrangeByIndex: true,
        maximumLabels: 10,
        labelPlacement: LabelPlacement.onTicks,
        axisLabelFormatter: (details) => ChartAxisLabel(
          details.text.startsWith("#") ? "" : details.text,
          details.textStyle,
        ),
      ),
      primaryYAxis: NumericAxis(
        minimum: (minPoint / 10000).floor() * 10000,
        maximum: (maxPoint / 10000).ceil() * 10000,
      ),
    ).constrained(height: 200);
  }
}

/// 返回缩略的局名："东1"
String formatRound(RoundData round) =>
    "${["东", "南", "西", "北"][round.wind]}${round.dealer + 1}";
