import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/openrouter_service.dart';
import '../../../data/models/chat_message.dart';
import '../../settings/providers/settings_providers.dart';
import 'chat_list_provider.dart';

class ChatScreenState {
  final List<ChatMessage> messages;
  final bool isSending;
  final String? error;

  const ChatScreenState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  ChatScreenState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? error,
  }) {
    return ChatScreenState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class ChatController extends StateNotifier<ChatScreenState> {
  final Ref ref;
  String? chatId;

  ChatController(this.ref) : super(const ChatScreenState());

  void loadSession(String? sessionId) {
    chatId = sessionId;
    if (sessionId == null) {
      state = const ChatScreenState();
      return;
    }
    final messages =
        ref.read(chatRepositoryProvider).getMessagesForSession(sessionId);
    state = ChatScreenState(messages: messages);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isSending) return;

    final repo = ref.read(chatRepositoryProvider);
    final apiKeyState = ref.read(apiKeyProvider);
    final apiKeyNotifier = ref.read(apiKeyProvider.notifier);
    final modelId = ref.read(activeChatModelProvider);
    final temperature = ref.read(temperatureProvider);
    final maxTokens = ref.read(maxTokensProvider);

    if (apiKeyState.status != ApiKeyStatus.valid) {
      state = state.copyWith(
        error: 'Add a valid OpenRouter API key in Settings to start chatting.',
      );
      return;
    }

    final apiKey = await apiKeyNotifier.getRawKey();
    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(
        error: 'Add a valid OpenRouter API key in Settings to start chatting.',
      );
      return;
    }

    // Create the session lazily on first message.
    if (chatId == null) {
      final title = text.trim().length > 40
          ? '${text.trim().substring(0, 40)}…'
          : text.trim();
      final session = repo.createSession(modelId: modelId, title: title);
      chatId = session.id;
      ref.read(chatSessionsProvider.notifier).state = repo.getAllSessions();
      ref.read(activeChatIdProvider.notifier).state = chatId;
    }

    final userMessage = await repo.addMessage(
      chatId: chatId!,
      content: text.trim(),
      role: MessageRole.user,
    );

    final assistantMessage = await repo.addMessage(
      chatId: chatId!,
      content: '',
      role: MessageRole.assistant,
      modelId: modelId,
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      isSending: true,
      error: null,
    );

    final service = ref.read(openRouterServiceProvider);
    final history = state.messages
        .where((m) => m.id != assistantMessage.id)
        .map((m) => OpenRouterMessage(
              role: m.role == MessageRole.user ? 'user' : 'assistant',
              content: m.content,
            ))
        .toList();

    final buffer = StringBuffer();

    try {
      await for (final chunk in service.streamChatCompletion(
        apiKey: apiKey,
        model: modelId,
        messages: history,
        temperature: temperature,
        maxTokens: maxTokens,
      )) {
        buffer.write(chunk);
        _updateAssistantMessage(assistantMessage.id, buffer.toString());
      }

      await repo.updateMessageContent(
        assistantMessage.id,
        buffer.toString(),
        isStreaming: false,
      );
      _updateAssistantMessage(
        assistantMessage.id,
        buffer.toString(),
        isStreaming: false,
      );
    } catch (e) {
      final errorText = buffer.isEmpty
          ? 'Failed to get a response: ${e.toString()}'
          : buffer.toString();
      await repo.updateMessageContent(
        assistantMessage.id,
        errorText,
        isStreaming: false,
        isError: buffer.isEmpty,
      );
      _updateAssistantMessage(
        assistantMessage.id,
        errorText,
        isStreaming: false,
        isError: buffer.isEmpty,
      );
    } finally {
      state = state.copyWith(isSending: false);
      ref.read(chatSessionsProvider.notifier).state = repo.getAllSessions();
    }
  }

  void _updateAssistantMessage(
    String messageId,
    String content, {
    bool isStreaming = true,
    bool isError = false,
  }) {
    final updated = state.messages.map((m) {
      if (m.id != messageId) return m;
      return m.copyWith(
        content: content,
        isStreaming: isStreaming,
        isError: isError,
      );
    }).toList();
    state = state.copyWith(messages: updated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatScreenState>((ref) {
  return ChatController(ref);
});
