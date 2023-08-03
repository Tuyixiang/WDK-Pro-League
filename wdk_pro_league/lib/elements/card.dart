import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

/// 可以点击的卡片
abstract class CardState<T extends StatefulWidget> extends State<T> {
  bool pressed = false;

  /// 卡片的高度
  double get height {
    return 80;
  }

  /// 卡片的宽度
  double get maxWidth {
    return 800;
  }

  @override
  Widget build(BuildContext context) {
    final card = Styled.widget(
            child: buildChild(context).padding(horizontal: 16, vertical: 8))
        .alignment(Alignment.center)
        .constrained(maxWidth: maxWidth)
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
        .constrained(height: height)
        .padding(horizontal: 12, vertical: 6) // margin
        .gestures(
          onTapChange: (tapStatus) => setState(() => pressed = tapStatus),
          onTapDown: (details) => print('tapDown'),
          onTap: onTap,
        )
        .scale(all: pressed ? 0.97 : 1.0, animate: true)
        .animate(const Duration(milliseconds: 150), Curves.easeOut);
    return buildWrapper(context, card);
  }

  /// 构建卡片中的元素
  Widget buildChild(BuildContext context);

  /// 在卡片外包裹元素
  Widget buildWrapper(BuildContext context, Widget card) {
    return card;
  }

  /// 卡片点击后的回调
  void onTap() {}
}
