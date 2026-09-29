import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../auth/session_controller.dart';
import 'chat_repository.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final int otherUserId;
  final String otherName;
  const ConversationScreen({super.key, required this.otherUserId, required this.otherName});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _input = TextEditingController();
  int? _conversationId;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conv = await repo.startConversation(widget.otherUserId);
      final id = conv['id'] as int;
      final messages = await repo.listMessages(id);
      await repo.markRead(id);
      if (mounted) {
        setState(() {
          _conversationId = id;
          _messages = messages; // newest first, from the API
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final conversationId = _conversationId;
    if (text.isEmpty || conversationId == null || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await ref.read(chatRepositoryProvider).sendMessage(conversationId, text);
      _input.clear();
      if (mounted) setState(() => _messages = [sent, ..._messages]);
    } catch (e) {
      if (mounted) showTnnSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = ref.watch(sessionControllerProvider).profile?['user_id'] as int?;
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const LoadingSkeleton()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _open)
                    : _messages.isEmpty
                        ? const EmptyState(icon: Icons.chat_bubble_outline, title: 'No messages yet', message: 'Say hello — this stays in-app, no phone number shared.')
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(TnnSpacing.lg),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final m = _messages[i];
                              final mine = m['sender_id'] == selfId;
                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: mine ? TnnColors.gold : TnnColors.card,
                                    border: mine ? null : Border.all(color: TnnColors.lineSoft),
                                    borderRadius: BorderRadius.circular(TnnRadius.lg),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(m['body'] ?? '', style: TextStyle(color: mine ? TnnColors.ink : TnnColors.ink, fontSize: 13.5)),
                                      const SizedBox(height: 3),
                                      Text(
                                        DateFormat('h:mm a').format(DateTime.parse(m['created_at'] as String).toLocal()),
                                        style: TextStyle(fontSize: 10, color: mine ? TnnColors.ink.withValues(alpha: 0.6) : TnnColors.inkSoft),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TnnSpacing.lg, 8, TnnSpacing.lg, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: 'Type a message'),
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    color: TnnColors.goldDeep,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
