import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/features/patient/chat/services/chatbot_service.dart';
import 'package:florence/features/patient/chat/models/chat_message.dart';

/// Chat Screen - AI Health Assistant
/// Conversational interface for health questions and guidance
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isTyping = false;

  // Suggested questions
  final List<String> _suggestedQuestions = [
    "How is my glucose trending?",
    "Any insights on my sleep?",
    "What should I eat for lunch?",
    "Am I meeting my activity goals?",
  ];
  
  @override
  void initState() {
    super.initState();
    // Initialize chat after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize chat: check cache or fetch history
  Future<void> _initializeChat() async {
    ref.read(chatProvider.notifier).loadHistory();
  }

  /// Confirm and clear history
  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to delete all chat history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
        if (mounted) {
          Helpers.showInfo(context, 'Chat history cleared');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showError(context, 'Failed to clear history');
        }
      }
    }
  }
  
  /// Send message
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageText = text.trim();
    _messageController.clear();

    try {
      await ref.read(chatProvider.notifier).sendMessage(messageText);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, "Failed to send message. Please try again.");
      }
    }
  }

  /// Scroll to bottom
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
  
  /// Send suggested question
  void _sendSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage(question);
  }
  
  /// Show info dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Health Assistant'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your AI assistant can help you:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('✓ Understand glucose patterns'),
              Text('✓ Get meal recommendations'),
              Text('✓ Receive activity suggestions'),
              Text('✓ Interpret your health data'),
              Text('✓ Get personalized insights'),
              SizedBox(height: 16),
              Text(
                'Note: This is an AI assistant. Always consult your healthcare provider for medical decisions.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final showLoading = chatState.isLoadingHistory || chatState.isClearingHistory;
    final loadingText = chatState.isClearingHistory 
        ? 'Clearing conversation history...' 
        : 'Syncing conversation history...';

    // Determine typing state
    final isTyping = messages.isNotEmpty && messages.last.isUser;

    // Scroll to bottom when messages change (and not loading)
    ref.listen(chatProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0) && !next.isLoadingHistory) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: showLoading ? null : _confirmClearHistory,
            tooltip: 'Clear History',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInfoDialog,
              tooltip: 'About AI Assistant',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested questions (only show if history is empty and not loading)
          if (!showLoading && messages.isEmpty) 
            _buildSuggestedQuestions(),
          
          // Chat messages area
          Expanded(
            child: showLoading
                ? _buildLoadingState(loadingText)
                : messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(messages),
          ),
          
          // Typing indicator
          if (isTyping && !showLoading) _buildTypingIndicator(),
          
          // Input area
          _buildInputArea(isEnabled: !showLoading),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build suggested questions
  Widget _buildSuggestedQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested questions:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedQuestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(_suggestedQuestions[index]),
                    onPressed: () => _sendSuggestedQuestion(
                      _suggestedQuestions[index],
                    ),
                    backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about your health!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }
  
  /// Build messages list
  Widget _buildMessagesList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _buildMessageBubble(message);
      },
    );
  }
  
  /// Build single message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Align(
          alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(
              maxWidth: math.min(MediaQuery.of(context).size.width * 0.75, 600),
            ),
            child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryBlue
                    : Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: message.isUser
                            ? Colors.white
                            : AppTheme.getTextPrimaryColor(context),
                        height: 1.4,
                      ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: message.isUser
                        ? Colors.white
                        : AppTheme.getTextPrimaryColor(context),
                  ),
                  listBullet: TextStyle(
                    color: message.isUser
                        ? Colors.white
                        : AppTheme.getTextPrimaryColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatTime(message.timestamp.toLocal()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
  
  /// Build typing indicator
  Widget _buildTypingIndicator() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build single typing dot
  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3 + (0.7 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
  
  /// Build input area
  Widget _buildInputArea({required bool isEnabled}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: AbsorbPointer(
                absorbing: !isEnabled,
                child: Row(
                  children: [
                    // Text input
                    Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.getBackgroundColor(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: isEnabled ? 'Ask me anything...' : 'Connecting...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        // Microphone button (placeholder)
                        IconButton(
                          icon: Icon(
                            Icons.mic_outlined,
                            color: AppTheme.textSecondaryColor,
                          ),
                          onPressed: () {
                            Helpers.showInfo(context, 'Voice input coming soon');
                          },
                          tooltip: 'Voice input',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_messageController.text),
                    tooltip: 'Send',
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
      ),
    );
  }
  
  /// Format timestamp
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
