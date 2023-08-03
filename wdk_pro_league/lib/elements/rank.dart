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

Widget buildRankText(BuildContext context, int dan) {
  final theme = Theme.of(context);
  return Text(
    '${danNames[dan]}段',
    style: theme.textTheme.labelSmall,
  )
      .padding(horizontal: 3)
      .limitedBox()
      .backgroundColor(Colors.grey.shade300)
      .clipRRect(all: 10);
}
