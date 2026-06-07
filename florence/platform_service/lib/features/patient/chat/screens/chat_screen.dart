import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/features/patient/chat/services/chatbot_service.dart';
import 'package:florence/features/patient/chat/models/chat_message.dart';
import 'package:florence/features/patient/profile/providers/user_profile_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _suggestedQuestions = [
    "How is my glucose trending?",
    "Any insights on my sleep?",
    "What should I eat for lunch?",
    "Am I meeting my activity goals?",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all chat history? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(chatProvider.notifier).clearHistory();
      } catch (e) {}
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageText = text.trim();
    _messageController.clear();

    try {
      await ref.read(chatProvider.notifier).sendMessage(messageText);
      _scrollToBottom();
    } catch (e) {
      if (mounted) Helpers.showError(context, "Failed to send message.");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final profile = ref.watch(userProfileProvider).value;
    final messages = chatState.messages;
    final showLoading = chatState.isLoadingHistory || chatState.isClearingHistory;
    final isTyping = messages.isNotEmpty && messages.last.isUser;

    ref.listen(chatProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0) && !next.isLoadingHistory) {
        _scrollToBottom();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.midnightBackground : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Chatbot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: isDark ? AppTheme.midnightSurface : Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppTheme.getBorderColor(context), height: 1.0),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: showLoading ? null : _confirmClearHistory),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: showLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessagesList(messages, profile),
              ),
            ),
          ),
          if (isTyping && !showLoading) Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: _buildTypingIndicator())),
          if (!showLoading && messages.isEmpty) Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: _buildSuggestedQuestions())),
          _buildInputArea(isEnabled: !showLoading),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.favorite_rounded, size: 40, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 24),
          Text('How can I help you today?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Ask about your health data, meals or insights.', style: TextStyle(color: AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages, Map<String, dynamic>? profile) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _buildMessageBubble(message, profile);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Map<String, dynamic>? profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget? avatar;
    if (message.isUser) {
      final avatarUrl = profile?['profile_picture_url'] as String?;
      final name = profile?['name'] as String? ?? 'U';
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        avatar = CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatarUrl));
      } else {
        avatar = CircleAvatar(
          radius: 16, 
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
          child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold)),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
          ],
          if (message.isUser) const SizedBox(width: 32), // Spacer for visual balance
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppTheme.primaryBlue 
                    : (isDark ? AppTheme.midnightSurface : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: message.isUser ? [] : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
                border: message.isUser ? null : Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: message.isUser ? Colors.white : AppTheme.getTextPrimaryColor(context),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            avatar!,
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.midnightSurface : Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4)),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: _BouncingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(_suggestedQuestions[index]),
              onPressed: () => _sendMessage(_suggestedQuestions[index]),
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              side: BorderSide(color: AppTheme.getBorderColor(context)),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea({required bool isEnabled}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.midnightSurface : Colors.white,
        border: Border(top: BorderSide(color: AppTheme.getBorderColor(context))),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.getBorderColor(context), width: 1.0),
                    ),
                    child: Focus(
                      onKeyEvent: (node, event) {
                        // Check for Enter key on Desktop/Web
                        if (Helpers.isDesktop(context) && 
                            event is KeyDownEvent && 
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          
                          // If holding Shift, let it create a new line naturally
                          if (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                              HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight)) {
                            return KeyEventResult.ignored; 
                          } else {
                            // Send message and prevent newline
                            if (_messageController.text.trim().isNotEmpty) {
                              _sendMessage(_messageController.text);
                            }
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _messageController,
                        enabled: isEnabled,
                        decoration: const InputDecoration(
                          hintText: 'Message Florence...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                    onPressed: isEnabled ? () => _sendMessage(_messageController.text) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  @override
  __BouncingDotsState createState() => __BouncingDotsState();
}

class __BouncingDotsState extends State<_BouncingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double offset = math.sin((_controller.value * 2 * math.pi) + (index * math.pi / 2));
            return Transform.translate(
              offset: Offset(0, offset * -3),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }
}
