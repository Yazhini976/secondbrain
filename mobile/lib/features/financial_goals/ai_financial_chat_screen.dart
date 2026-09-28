import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/features/financial_goals/data/financial_api.dart';
import 'package:second_brain/features/financial_goals/data/financial_repository.dart';

class ChatMessageItem {
  final String sender; // 'user' or 'ai'
  final String text;
  final List<String> suggestions;

  ChatMessageItem({
    required this.sender,
    required this.text,
    this.suggestions = const [],
  });
}

class AIFinancialChatScreen extends StatefulWidget {
  const AIFinancialChatScreen({super.key});

  @override
  State<AIFinancialChatScreen> createState() => _AIFinancialChatScreenState();
}

class _AIFinancialChatScreenState extends State<AIFinancialChatScreen> {
  final List<ChatMessageItem> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FinancialApi _api = FinancialApi();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessageItem(
        sender: 'ai',
        text: 'Hello! I am your Second Brain Financial Intelligence Assistant. '
            'I analyze your deterministic cash flow and goal feasibility in real-time.\n\n'
            'How can I help you today?',
        suggestions: [
          'Why are my goals conflicting?',
          'What should I do?',
          'What are my goals?',
          'What is my income?',
          'Show my expenses',
          'Show alternatives',
          'What if I save ₹5,000 more?',
        ],
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String query) async {
    if (query.trim().isEmpty || _isSending) return;

    final userQuery = query.trim();
    _textController.clear();

    setState(() {
      _messages.add(ChatMessageItem(sender: 'user', text: userQuery));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final res = await _api.sendAIChatMessage(userQuery);
      final replyText = (res['reply'] ?? 'Unable to process question.') as String;
      final rawSugg = (res['suggested_actions'] as List<dynamic>?) ?? [];
      final suggList = rawSugg.map((s) => s.toString()).toList();

      setState(() {
        _messages.add(
          ChatMessageItem(
            sender: 'ai',
            text: replyText,
            suggestions: suggList,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();

      // Reload analysis in repo if conflict/scenarios changed
      try {
        await FinancialRepository.instance.loadAnalysis();
      } catch (_) {}
    } catch (e) {
      debugPrint('AI Chat Error: $e');
      setState(() {
        _messages.add(
          ChatMessageItem(
            sender: 'ai',
            text: 'I could not connect to the financial server ($e).\n\nPlease ensure the backend is running and you have an active network connection.',
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Intelligence AI'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.space16),
                itemCount: _messages.length,
                itemBuilder: (ctx, idx) {
                  final msg = _messages[idx];
                  final isUser = msg.sender == 'user';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space16),
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.space12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.darkBlue
                                : AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isUser
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                              bottomRight: isUser
                                  ? Radius.zero
                                  : const Radius.circular(12),
                            ),
                            border: isUser
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: isUser ? Colors.white : AppColors.darkText,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (!isUser && msg.suggestions.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: msg.suggestions.map((sugg) {
                              return ActionChip(
                                label: Text(sugg, style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.veryLightBlue,
                                side: BorderSide.none,
                                onPressed: () => _sendMessage(sugg),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_isSending)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(color: AppColors.darkBlue),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space8,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Ask financial question...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.darkBlue),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
