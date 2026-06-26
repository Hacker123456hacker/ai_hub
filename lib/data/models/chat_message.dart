import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 1)
enum MessageRole {
  @HiveField(0)
  user,
  @HiveField(1)
  assistant,
  @HiveField(2)
  system,
}

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  String content;

  @HiveField(3)
  final MessageRole role;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? modelId;

  @HiveField(6)
  bool isError;

  @HiveField(7)
  bool isStreaming;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.content,
    required this.role,
    required this.createdAt,
    this.modelId,
    this.isError = false,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isError,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      content: content ?? this.content,
      role: role,
      createdAt: createdAt,
      modelId: modelId,
      isError: isError ?? this.isError,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
