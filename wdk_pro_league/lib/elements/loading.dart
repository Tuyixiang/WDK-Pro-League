import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

/// 加载界面及逻辑

class Loading with ChangeNotifier {
  int value = 0;

  void start() {
    value += 1;
    notifyListeners();
  }

  void end() {
    value -= 1;
    notifyListeners();
  }

  Future<T> on<T>(Future<T> Function() func) async {
    await Future.delayed(const Duration());
    if (!const bool.fromEnvironment('dart.vm.product')) {
      // 在测试环境下等待以模拟网络环境
      await Future.delayed(const Duration(milliseconds: 500));
    }
    start();
    return func().whenComplete(end);
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (Provider.of<Loading>(context).value > 0) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SizedBox(
            height: 60,
            width: 60,
            child: LoadingIndicator(
              indicatorType: Indicator.lineScale,
              colors: [Colors.black26],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
