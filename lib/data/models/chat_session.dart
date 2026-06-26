import 'package:hive/hive.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 2)
class ChatSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String modelId;

  @HiveField(5)
  bool isPinned;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.modelId,
    this.isPinned = false,
  });
}
