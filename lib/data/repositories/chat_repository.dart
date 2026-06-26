import 'package:uuid/uuid.dart';
import '../local/hive_service.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

/// Mediates between the UI/state layer and Hive boxes for all chat data.
class ChatRepository {
  final _uuid = const Uuid();

  // ---- Sessions ----

  List<ChatSession> getAllSessions() {
    final sessions = HiveService.chatBox.values.toList();
    sessions.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sessions;
  }

  ChatSession createSession({required String modelId, String? title}) {
    final session = ChatSession(
      id: _uuid.v4(),
      title: title ?? 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      modelId: modelId,
    );
    HiveService.chatBox.put(session.id, session);
    return session;
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final session = HiveService.chatBox.get(sessionId);
    if (session == null) return;
    session.title = newTitle;
    session.updatedAt = DateTime.now();
    await session.save();
  }

  Future<void> touchSession(String sessionId) async {
    final session = HiveService.chatBox.get(sessionId);
    if (session == null) return;
    session.updatedAt = DateTime.now();
    await session.save();
  }

  Future<void> togglePin(String sessionId) async {
    final session = HiveService.chatBox.get(sessionId);
    if (session == null) return;
    session.isPinned = !session.isPinned;
    await session.save();
  }

  Future<void> deleteSession(String sessionId) async {
    await HiveService.chatBox.delete(sessionId);
    final messageKeys = HiveService.messageBox.values
        .where((m) => m.chatId == sessionId)
        .map((m) => m.key)
        .toList();
    await HiveService.messageBox.deleteAll(messageKeys);
  }

  // ---- Messages ----

  List<ChatMessage> getMessagesForSession(String sessionId) {
    final messages = HiveService.messageBox.values
        .where((m) => m.chatId == sessionId)
        .toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<ChatMessage> addMessage({
    required String chatId,
    required String content,
    required MessageRole role,
    String? modelId,
    bool isStreaming = false,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      chatId: chatId,
      content: content,
      role: role,
      createdAt: DateTime.now(),
      modelId: modelId,
      isStreaming: isStreaming,
    );
    await HiveService.messageBox.put(message.id, message);
    await touchSession(chatId);
    return message;
  }

  Future<void> updateMessageContent(
    String messageId,
    String newContent, {
    bool? isStreaming,
    bool? isError,
  }) async {
    final message = HiveService.messageBox.get(messageId);
    if (message == null) return;
    message.content = newContent;
    if (isStreaming != null) message.isStreaming = isStreaming;
    if (isError != null) message.isError = isError;
    await message.save();
  }

  Future<void> deleteMessage(String messageId) async {
    await HiveService.messageBox.delete(messageId);
  }
}
