import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'game_data.dart';
import 'player_data.dart';

/// 从后端 API 获取数据

final dio = Dio();

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
          response.data.map((obj) => GamePreview.fromJson(obj)));
    } catch (e) {
      print(e);
      final data = (await sampleData)["gameHistory"];
      return List<GamePreview>.from(
          data.map((obj) => GamePreview.fromJson(obj)));
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
      return GameData.fromJson(response.data);
    } catch (e) {
      print(e);
      return GameData.fromJson((await sampleData)["game"]);
    }
  }

  /// 查询游戏信息
  static Future<GameData> getGameData(String gameId) async {
    return cachedGameData[gameId] ??= await _fetchGameData(gameId);
  }

  /// 上传游戏 JSON
  static Future<Map<String, String>> uploadGames(
      Map<String, String> payload) async {
    try {
      final response =
          await dio.post("$apiBaseUrl/api/post/tenhou_game", data: payload);
      return response.data.cast<String, String>();
    } catch (e) {
      print(e);
      return payload.map((key, value) => MapEntry(key, "网络错误"));
    } finally {
      // 清除已缓存的数据
      IO.cachedLeaderBoard = null;
      IO.cachedGameHistory = null;
    }
  }
}
