import 'package:json_annotation/json_annotation.dart';
import 'package:shorebird/datastore.dart';

part 'model.g.dart';

// @Transportable
@ObjectIdConverter()
@JsonSerializable(constructor: '_')
class Message {
  final ObjectId id;
  final String message;
  final DateTime time;
  Message(this.message, this.time) : id = ObjectId();

  Message._(this.id, this.message, this.time);

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
