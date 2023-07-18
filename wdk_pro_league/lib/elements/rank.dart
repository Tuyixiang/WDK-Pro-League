import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

Widget buildRankText(BuildContext context, int rank) {
  final theme = Theme.of(context);
  return Text(
    '$rank段',
    style: theme.textTheme.labelSmall,
  )
      .padding(horizontal: 3)
      .limitedBox()
      .backgroundColor(Colors.grey.shade300)
      .clipRRect(all: 10);
}
