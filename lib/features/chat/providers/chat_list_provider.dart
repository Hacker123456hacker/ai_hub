import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/chat_session.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../settings/providers/settings_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// List of all chat sessions, sorted pinned-first then most-recent.
/// Call `ref.invalidate(chatSessionsProvider)` after any mutation to refresh.
final chatSessionsProvider = StateProvider<List<ChatSession>>((ref) {
  return ref.read(chatRepositoryProvider).getAllSessions();
});

/// The currently open chat session id, null if on the "new chat" / home state.
final activeChatIdProvider = StateProvider<String?>((ref) => null);

final activeChatModelProvider = Provider<String>((ref) {
  final activeChatId = ref.watch(activeChatIdProvider);
  if (activeChatId == null) {
    return ref.watch(selectedModelProvider);
  }
  final sessions = ref.watch(chatSessionsProvider);
  final session = sessions.where((s) => s.id == activeChatId).firstOrNull;
  return session?.modelId ?? ref.watch(selectedModelProvider);
});
