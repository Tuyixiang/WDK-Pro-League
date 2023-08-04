import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// 从后端 API 获取数据

final dio = Dio();

callIfNotNull(Function func, Object? obj) {
  if (obj == null) {
    return null;
  }
  return func(obj);
}

/// 完整的玩家数据
class PlayerData {
  /// 玩家 ID
  final String playerId;

  /// 玩家显示名称
  final String playerName;

  /// 玩家外部 ID
  final int externalId;

  /// 当前段位
  final int currentDan;

  /// 最高段位
  final int highestDan;

  /// 当前 pt
  final int currentPt;

  /// 最高 pt
  final int highestDanPt;

  /// 升级所需分数
  final int thresholdPt;

  /// 当前 R 值
  final double rValue;

  /// 所有过往游戏，按时间顺序排序
  final List<GamePreview> gameHistory;

  /// 过往游戏局数
  final int gameCount;

  /// 拿到每种顺位的次数
  final List<int> orderCount;

  PlayerData(Map<String, dynamic> data)
      : playerId = data["player_id"],
        playerName = data["player_name"],
        externalId = data["external_id"],
        currentDan = data["current_dan"],
        highestDan = data["highest_dan"],
        currentPt = data["current_pt"],
        highestDanPt = data["highest_dan_pt"],
        thresholdPt = data["threshold_pt"],
        rValue = data["r_value"],
        gameHistory = List<GamePreview>.from(
          data["game_history"].map((v) => GamePreview(v)),
        ),
        gameCount = data["game_count"],
        orderCount = data["order_count"].cast<int>();
}

/// 部分的玩家数据
class PlayerPreview {
  /// 玩家 ID
  final String playerId;

  /// 玩家显示名称
  final String playerName;

  /// 当前分数
  final int currentPt;

  /// 当前段位
  final int currentDan;

  /// 升级所需分数
  final int thresholdPt;

  /// 当前 R 值
  final double rValue;

  /// 过往游戏局数
  final int gameCount;

  /// 拿到每种顺位的次数
  final List<int> orderCount;

  PlayerPreview(Map<String, dynamic> data)
      : playerId = data["player_id"],
        playerName = data["player_name"],
        currentPt = data["current_pt"],
        currentDan = data["current_dan"],
        thresholdPt = data["threshold_pt"],
        rValue = data["r_value"].toDouble(),
        gameCount = data["game_count"],
        orderCount = data["order_count"].cast<int>();
}

/// 完整的游戏数据
class GameData {
  /// 参与的玩家，按照座位顺序
  final List<PlayerPreview> players;

  /// 每个玩家获得的点数（当盘游戏的点数，非玩家累计点数）
  final List<int> playerPoints;

  /// 每一局的结果，可能为空（只计点数）
  final List<dynamic> rounds;

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
        rounds = data["rounds"],
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

/// Placeholder 数据
Future<Map<String, dynamic>> sampleData =
    rootBundle.loadString("assets/sampleData.json").then((string) {
  var obj = jsonDecode(string);
  return obj;
});

/// 在测试环境使用本地后端 URL
String get apiBaseUrl {
  if (const bool.fromEnvironment('dart.vm.product')) {
    return "";
  }
  return "http://127.0.0.1:5000";
}

class IO {
  static List<PlayerPreview>? cachedLeaderBoard;
  static List<GamePreview>? cachedGameHistory;
  static final Map<String, PlayerData> cachedPlayerData = {};
  static final Map<String, GameData> cachedGameData = {};

  /// 从后端抓取排行榜
  static Future<List<PlayerPreview>> _fetchLeaderBoard() async {
    try {
      final response = await dio.get("$apiBaseUrl/api/access/leader_board");
      return List<PlayerPreview>.from(
          response.data.map((obj) => PlayerPreview(obj)));
    } catch (e) {
      print(e);
      final data = (await sampleData)["leaderBoard"];
      return List<PlayerPreview>.from(data.map((obj) => PlayerPreview(obj)));
    }
  }

  /// 获取排行榜
  static Future<List<PlayerPreview>> getLeaderBoard() async {
    return cachedLeaderBoard ??= await _fetchLeaderBoard();
  }

  /// 从后端抓取全部游戏记录
  static Future<List<GamePreview>> _fetchGameHistory() async {
    try {
      final response = await dio.get("$apiBaseUrl/api/access/game_history");
      return List<GamePreview>.from(
          response.data.map((obj) => GamePreview(obj)));
    } catch (e) {
      print(e);
      final data = (await sampleData)["gameHistory"];
      return List<GamePreview>.from(data.map((obj) => GamePreview(obj)));
    }
  }

  /// 获取全部游戏记录
  static Future<List<GamePreview>> getGameHistory() async {
    return cachedGameHistory ??= await _fetchGameHistory();
  }

  /// 从后端抓取玩家信息
  static Future<PlayerData> _fetchPlayerData(String playerId) async {
    try {
      final response =
          await dio.get("$apiBaseUrl/api/query/player", queryParameters: {
        "player_id": playerId,
      });
      return PlayerData(response.data);
    } catch (e) {
      print(e);
      return PlayerData((await sampleData)["player"]);
    }
  }

  /// 查询玩家信息
  static Future<PlayerData> getPlayerData(String playerId) async {
    return cachedPlayerData[playerId] ??= await _fetchPlayerData(playerId);
  }

  /// 从后端抓取游戏信息
  static Future<GameData> _fetchGameData(String gameId) async {
    try {
      final response =
          await dio.get("$apiBaseUrl/api/query/game", queryParameters: {
        "game_id": gameId,
      });
      return GameData(response.data);
    } catch (e) {
      print(e);
      return GameData((await sampleData)["game"]);
    }
  }

  /// 查询游戏信息
  static Future<GameData> getGameData(String gameId) async {
    return cachedGameData[gameId] ??= await _fetchGameData(gameId);
  }
}
