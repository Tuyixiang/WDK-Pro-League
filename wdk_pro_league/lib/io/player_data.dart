import 'game_data.dart';

/// 完整的玩家数据
class PlayerData {
  /// 玩家 ID
  final String playerId;

  /// 玩家显示名称
  final String playerName;

  /// 玩家外部 ID
  final List<int> externalIds;

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
        externalIds = data["external_ids"].cast<int>(),
        currentDan = data["current_dan"],
        highestDan = data["highest_dan"],
        currentPt = data["current_pt"],
        highestDanPt = data["highest_dan_pt"],
        thresholdPt = data["threshold_pt"],
        rValue = data["r_value"],
        gameHistory = List<GamePreview>.from(
          data["game_history"].map((v) => GamePreview.fromJson(v)),
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
