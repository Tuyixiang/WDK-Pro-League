// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderBoard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderBoardPlayerInfo _$LeaderBoardPlayerInfoFromJson(
        Map<String, dynamic> json) =>
    LeaderBoardPlayerInfo(
      json['name'] as String,
      json['pt'] as int,
      (json['r'] as num).toDouble(),
      json['rank'] as int,
      json['gameCount'] as int,
      json['winCount'] as int,
    );

Map<String, dynamic> _$LeaderBoardPlayerInfoToJson(
        LeaderBoardPlayerInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'pt': instance.pt,
      'r': instance.r,
      'rank': instance.rank,
      'gameCount': instance.gameCount,
      'winCount': instance.winCount,
    };

LeaderBoardData _$LeaderBoardDataFromJson(Map<String, dynamic> json) =>
    LeaderBoardData(
      (json['playerInfoList'] as List<dynamic>)
          .map((e) => LeaderBoardPlayerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      DateTime.parse(json['updateTime'] as String),
    );

Map<String, dynamic> _$LeaderBoardDataToJson(LeaderBoardData instance) =>
    <String, dynamic>{
      'playerInfoList': instance.playerInfoList,
      'updateTime': instance.updateTime.toIso8601String(),
    };
