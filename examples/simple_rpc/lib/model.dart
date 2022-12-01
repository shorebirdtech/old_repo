import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

// @Transportable
@JsonSerializable()
class Message {
  final String message;
  final DateTime time;
  Message(this.message, this.time);

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
