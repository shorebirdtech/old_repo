import 'package:json_annotation/json_annotation.dart';
import 'package:shorebird/annotations.dart';
import 'package:shorebird/datastore.dart';

// WANT: Ghost text in editor to show me the fromJson, toJson and other methods.
// e.g. how Rust adds lots of ghost text.
// The point of ghost text is to de-magic the generated code.

part 'model.g.dart';

@Transportable()
@Storable()
@ObjectIdConverter()
@JsonSerializable(constructor: '_')
class Message {
  final ObjectId id;
  final String message;
  final DateTime time;
  Message(this.message, this.time) : id = ObjectId();

  Message._(this.id, this.message, this.time);

  // copyWith should be auto-generated.
  Message copyWith({String? message, DateTime? time}) {
    return Message._(id, message ?? this.message, time ?? this.time);
  }

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
