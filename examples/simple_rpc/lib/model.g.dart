// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message._(
      const ObjectIdConverter().fromJson(json['id'] as String),
      json['content'] as String,
      DateTime.parse(json['time'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': const ObjectIdConverter().toJson(instance.id),
      'content': instance.content,
      'time': instance.time.toIso8601String(),
    };
