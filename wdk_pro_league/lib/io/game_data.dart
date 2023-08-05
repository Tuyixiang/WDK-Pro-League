import 'package:wdk_pro_league/io/round_data.dart';

import 'player_data.dart';

callIfNotNull(Function func, Object? obj) {
  if (obj == null) {
    return null;
  }
  return func(obj);
}

/// 完整的游戏数据
class GameData {
  /// 参与的玩家，按照座位顺序
  final List<PlayerPreview> players;

  /// 每个玩家获得的点数（当盘游戏的点数，非玩家累计点数）
  final List<int> playerPoints;

  /// 每一局的结果，可能为空（只计点数）
  final List<RoundData> rounds;

  /// 实际进行游戏的日期
  final DateTime? gameDate;

  /// 游戏细节的外部链接，如果适用
  final String? externalId;

  /// Index 所用的唯一 key
  final String gameId;

  /// 上传时间（以服务器接受为准）
  final DateTime uploadTime;

  /// 玩家获得的分数
  final List<int> ptDelta;

  /// 玩家获得的 R
  final List<double> rDelta;

  /// 游戏的类型（雀魂或手动录入）
  final String gameType;

  GameData(Map<String, dynamic> data)
      : players = List<PlayerPreview>.from(
          data["players"].map((v) => PlayerPreview(v)),
        ),
        playerPoints = data["player_points"].cast<int>(),
        rounds = data["rounds"]
            .map<RoundData>((e) => RoundData.fromJson(e))
            .toList(),
        gameDate = callIfNotNull(DateTime.parse, data["game_date"]),
        externalId = data["external_id"],
        gameId = data["game_id"],
        uploadTime = DateTime.parse(data["upload_time"]),
        ptDelta = data["pt_delta"].cast<int>(),
        rDelta = data["r_delta"].cast<double>(),
        gameType = data["game_type"];
}

/// 部分的游戏数据
class GamePreview {
  /// 参与的玩家，按照座位顺序
  final List<PlayerPreview> players;

  /// 每个玩家获得的点数（当盘游戏的点数，非玩家累计点数）
  final List<int> playerPoints;

  /// 参与玩家的游戏结果排序
  final List<String> orderedPlayerIds;

  /// 游戏的日期
  final DateTime date;

  /// Index 所用的唯一 key
  final String gameId;

  /// 玩家获得的分数
  final List<int> ptDelta;

  /// 玩家获得的 R
  final List<double> rDelta;

  /// 游戏的类型（雀魂或手动录入）
  final String gameType;

  GamePreview(Map<String, dynamic> data)
      : players = List<PlayerPreview>.from(
          data["players"].map((v) => PlayerPreview(v)),
        ),
        playerPoints = data["player_points"].cast<int>(),
        orderedPlayerIds = data["ordered_player_ids"].cast<String>(),
        date = DateTime.parse(data["date"]),
        gameId = data["game_id"],
        ptDelta = data["pt_delta"].cast<int>(),
        rDelta = data["r_delta"].cast<double>(),
        gameType = data["game_type"];
}
