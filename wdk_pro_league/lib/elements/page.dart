import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

/// 创建一个标准的页面标题
AppBar buildAppBar({
  required BuildContext context,
  // 页面标题
  required String title,
  // 页面标题旁的动作按钮
  List<Widget>? actions,
}) =>
    AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))
          .center(),
      actions: actions,
    );

/// 打开一个页面（带有弹出动画）
Route loadPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    // 从下至上弹出的动画
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
