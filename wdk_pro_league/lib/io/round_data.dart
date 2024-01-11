import 'package:wdk_pro_league/io/helper.dart';

typedef WinningHand = (List<String>, List<List<String>>, String);

/// 一局游戏的情况
class RoundData {
  /// 场凤
  final int wind;

  /// 本场数
  final int honba;

  /// 供托数
  final int kyoutaku;

  /// 庄家
  final int dealer;

  /// 结局（中文）
  final String ending;

  /// 初始分数
  final List<int> initialPoints;

  /// 分数增减（至少一项）
  final List<List<int>> resultPoints;

  /// 立直状态
  final List<bool> riichiStatus;

  /// 和牌情况
  final List<Win> wins;

  final List<WinningHand>? finalHands;

  RoundData({
    required this.wind,
    required this.honba,
    required this.kyoutaku,
    required this.dealer,
    required this.ending,
    required this.initialPoints,
    required this.resultPoints,
    required this.riichiStatus,
    required this.wins,
    this.finalHands,
  });

  /// 加载 JSON 对
  static RoundData fromJson(Map<String, dynamic> obj) => RoundData(
      wind: obj["prevailing_wind"],
      honba: obj["honba"],
      kyoutaku: obj["kyoutaku"],
      dealer: obj["dealer"],
      ending: obj["ending"],
      initialPoints: obj["initial_points"].cast<int>(),
      resultPoints: obj["result_points"]
          .map<List<int>>((e) => List<int>.from(e))
          .toList(),
      riichiStatus: obj["riichi_status"].cast<bool>(),
      wins: obj["wins"].map<Win>((e) => Win.fromJson(e)).toList(),
      finalHands: obj["final_hands"]
          .map<WinningHand>((e) => (
                e[0].cast<String>(),
                e[1].map<List<String>>((e) => List<String>.from(e)).toList(),
                e[2],
              ) as WinningHand)
          .toList());
}

/// 一个和牌的情况
class Win {
  /// 和牌者
  final int winner;

  /// 点炮（自摸则与和牌者相同）
  final int loser;

  /// 番数
  final int han;

  /// 符数（对于满贯及以上可能不准）
  final int fu;

  /// 役满倍数
  final int yakuman;

  /// 役种，番数，役满倍数
  final List<(String, int, int)> yaku;

  Win({
    required this.winner,
    required this.loser,
    required this.han,
    required this.fu,
    required this.yakuman,
    required this.yaku,
  });

  /// 加载 JSON 对象
  static Win fromJson(Map<String, dynamic> obj) => Win(
        winner: obj["winner"],
        loser: obj["loser"],
        han: obj["han"],
        fu: obj["fu"],
        yakuman: obj["yakuman"],
        yaku: obj["yaku"]
            .map<(String, int, int)>((e) =>
                (cast<String>(e[0])!, cast<int>(e[1])!, cast<int>(e[2])!))
            .toList(),
      );
}
