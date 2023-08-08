import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

const List<String> danNames = [
  "初",
  "二",
  "三",
  "四",
  "五",
  "六",
  "七",
  "八",
  "九",
  "十",
];

/// 绘制段位的小元素
Widget buildDan(BuildContext context, int dan) => Text(
      '${danNames[dan]}段',
      style: Theme.of(context).textTheme.labelSmall,
    )
        .invertWithColor(
          Colors.grey.withAlpha(96),
          radius: 4,
          foreground: Colors.black,
        )
        .padding(top: 1.5);

/// 风的名字
const List<String> windNames = ["东", "南", "西", "北"];

/// 汉字数字
const List<String> numberNames = ["一", "二", "三", "四"];

/// 绘制座位（东南西北）可选高亮东
Widget buildSeat(BuildContext context, int seat, {bool highlight = false}) {
  if (highlight) {
    return Text(windNames[seat], style: const TextStyle(fontSize: 16))
        .invertWithColor(Theme.of(context).disabledColor);
  } else {
    return Text(
      windNames[seat],
      style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
    );
  }
}

/// 绘制玩家名+段位标记
Widget buildPlayerName(BuildContext context, String name, int? dan,
    [bool autoBreak = true]) {
  final nameWidget = Text(
    name,
    style: Theme.of(context)
        .textTheme
        .bodyLarge!
        .copyWith(fontWeight: FontWeight.bold),
  );
  if (dan == null) {
    return nameWidget;
  } else if (autoBreak) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [nameWidget, buildDan(context, dan)],
    );
  } else {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [nameWidget.padding(right: 2), buildDan(context, dan)],
    );
  }
}

/// 将文字包裹为指定颜色背景、白色文字的圆角矩形
extension InvertedText on Text {
  Widget invertWithColor(Color color,
          {Color foreground = Colors.white, double radius = 10}) =>
      textColor(foreground)
          .padding(horizontal: radius / 2)
          .limitedBox()
          .backgroundColor(color)
          .clipRRect(all: radius);
}
