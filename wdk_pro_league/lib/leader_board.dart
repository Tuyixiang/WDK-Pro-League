import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import 'elements/basic.dart';
import 'elements/card.dart';
import 'elements/loading.dart';
import 'elements/page.dart';
import 'game_history.dart';
import 'io/io.dart';
import 'io/player_data.dart';
import 'player_view.dart';

/// Leader Board Page
class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({super.key});

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  List<PlayerPreview> data = [];
  bool initialized = false;

  _LeaderBoardPageState() {
    if (IO.cachedLeaderBoard != null) {
      data = IO.cachedLeaderBoard!;
      initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      print("Start initializing leader board");
      initialized = true;
      Provider.of<Loading>(context).on(IO.getLeaderBoard).then((data) {
        print("Leader board data fetched");
        setState(() {
          this.data = data;
        });
      });
    }
    return Scaffold(
      appBar: buildAppBar(
        context: context,
        title: "WDK Pro League 排行榜",
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(loadPage(const GameHistoryPage()));
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      // body: 排行榜
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) =>
            PlayerCard(index: index, info: data[index]),
      ),
      // 悬浮按钮：上传 json
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          // 上传 JSON
          final resultStrings =
              await Provider.of<Loading>(context, listen: false).on(() async {
            // 记录每个文件的上传结果
            final resultStrings = <String, String>{};
            // 建造上传给服务器的对象
            final postObject = <String, String>{};
            // 弹窗请用户选择文件
            final picks =
                await FilePicker.platform.pickFiles(allowMultiple: true);
            // 处理无法打开和非 JSON 的文件，并将合法文件放入 postObject
            picks?.files.forEach((file) {
              try {
                final content = utf8.decode(file.bytes!);
                // 检验文件内容为合法 JSON
                jsonDecode(content);
                // 放入上传对象中
                postObject[file.name] = content;
              } on FormatException {
                resultStrings[file.name] = "不是 JSON 文件";
              } catch (e) {
                print(e);
                resultStrings[file.name] = "无法读取文件";
              }
            });
            // 发送请求
            if (postObject.isNotEmpty) {
              final response = await IO.uploadGames(postObject);
              resultStrings.addAll(response);
            }
            return resultStrings;
          });
          // 显示结果
          if (!mounted) {
            return;
          }
          await makePrompt(
              context,
              "上传结果",
              resultStrings.entries
                  .map<String>((e) => "${e.key}：${e.value}")
                  .join("\n"));
          // 刷新页面
          setState(() {
            initialized = false;
            data = [];
          });
        },
      ),
    );
  }
}

/// Card displaying each player
class PlayerCard extends StatefulWidget {
  /// Index in list (first place is 0)
  final int index;
  final PlayerPreview info;

  const PlayerCard({super.key, required this.index, required this.info});

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends CardState<PlayerCard> {
  Color colorFromIndex(i) {
    final themeColor = Theme.of(context).primaryColor;
    if (i == 0) {
      return themeColor;
    } else if (i == 1) {
      return Color.alphaBlend(Colors.white30, themeColor);
    } else if (i == 2) {
      return Color.alphaBlend(Colors.white60, themeColor);
    } else {
      return Colors.grey.shade300;
    }
  }

  @override
  Widget buildChild(BuildContext context) {
    final Widget index = Text(
      (widget.index + 1).toString(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 36,
      ),
    )
        .center()
        .card(shape: const CircleBorder(), color: colorFromIndex(widget.index))
        .width(60)
        .padding(right: 8);

    final Widget name =
        buildPlayerName(context, widget.info.playerName, widget.info.currentDan)
            .padding(bottom: 5);

    final String orderText;
    if (widget.info.gameCount == 0) {
      orderText = '暂无数据';
    } else {
      orderText = widget.info.orderCount.join("/");
    }
    final descriptionStyle = TextStyle(
      color: Theme.of(context).disabledColor,
      fontSize: 14,
    );
    final description = Wrap(
      alignment: WrapAlignment.start,
      spacing: 12,
      children: [
        Text(
          'pt: ${widget.info.currentPt}/${widget.info.thresholdPt}',
          style: descriptionStyle,
        ),
        Text(
          '战绩: $orderText',
          style: descriptionStyle,
        ),
        Text(
          'R: ${widget.info.rValue.round()}',
          style: descriptionStyle,
        ),
      ],
    );

    return Row(children: [
      index,
      Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            name,
            description,
          ]),
    ]);
  }

  /// 点击时展开玩家详情页面
  @override
  void onTap(BuildContext context) {
    Future.delayed(const Duration()).then((a) {
      Navigator.of(context)
          .push(loadPage(PlayerViewPage(playerId: widget.info.playerId)));
    });
  }
}
