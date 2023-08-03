import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wdk_pro_league/elements/loading.dart';
import 'leader_board.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Loading(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WDK Pro League',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: "AlibabaPuHuiTi",
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Widget activeWidget;

  _MyHomePageState() : activeWidget = const LeaderBoardPage();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context).insert(OverlayEntry(
        builder: (context) => const LoadingWidget(),
      ));
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth * 1.5 < constraints.maxHeight) {
          return _buildForVerticalScreen(context);
        } else {
          return _buildForHorizontalScreen(context);
        }
      },
    )
        // floatingActionButton: FloatingActionButton(
        //   onPressed: _incrementCounter,
        //   tooltip: 'Increment',
        //   child: const Icon(Icons.add),
        // ), // This trailing comma makes auto-formatting nicer for build methods.
        ;
  }

  /// Build UI for mobile phones
  Widget _buildForVerticalScreen(BuildContext context) {
    return activeWidget;
  }

  /// Build UI for iPad/PC
  Widget _buildForHorizontalScreen(BuildContext context) {
    // todo
    return _buildForVerticalScreen(context);
  }
}
