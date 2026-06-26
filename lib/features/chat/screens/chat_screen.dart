import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/chat_controller_provider.dart';
import '../providers/chat_list_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/model_picker_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final activeModel = ref.watch(activeChatModelProvider);

    ref.listen(chatControllerProvider, (previous, next) {
      final lengthChanged =
          next.messages.length != (previous?.messages.length ?? -1);
      final lastContentChanged = previous != null &&
          previous.messages.isNotEmpty &&
          next.messages.isNotEmpty &&
          next.messages.last.content != previous.messages.last.content;

      if (lengthChanged || lastContentChanged) {
        _scrollToBottom();
      }
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(chatControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showModelPicker(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _shortModelName(activeModel),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).hintColor),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? const _ChatEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: chatState.messages[index]);
                    },
                  ),
          ),
          ChatInputBar(
            isSending: chatState.isSending,
            onSend: (text) {
              ref.read(chatControllerProvider.notifier).sendMessage(text);
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }

  String _shortModelName(String modelId) {
    final match = OpenRouterModels.popular.where((m) => m['id'] == modelId);
    if (match.isNotEmpty) return match.first['name']!;
    final parts = modelId.split('/');
    return parts.length > 1 ? parts.last : modelId;
  }
}

class _ChatEmptyState extends ConsumerWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKeyState = ref.watch(apiKeyProvider);
    final hasKey = apiKeyState.status == ApiKeyStatus.valid;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              hasKey ? 'Ask me anything' : 'Add your OpenRouter API key',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasKey
                  ? 'Pick a model up top and start typing below.'
                  : 'Open Settings to paste your key before you can start chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
