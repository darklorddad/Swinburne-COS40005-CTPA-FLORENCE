import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../core/config/environment.dart';
import '../services/chatbot_service.dart';
import '../models/chat_message.dart';

/// Chat Screen - AI Health Assistant
/// Conversational interface for health questions and guidance
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatbotService = ChatbotService(); // Uses the singleton instance
  
  bool _isTyping = false;
  bool _isLoadingHistory = true;

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
    // Listen to service updates (e.g. when background messages arrive)
    _chatbotService.addListener(_onServiceUpdate);
    _initializeChat();
  }

  @override
  void dispose() {
    _chatbotService.removeListener(_onServiceUpdate);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Called whenever the service notifies of changes
  void _onServiceUpdate() {
    if (mounted) {
      setState(() {
        // The UI rebuilds using _chatbotService.messages directly
        // We check if the last message is from user to determine typing state
        if (_chatbotService.messages.isNotEmpty) {
          _isTyping = _chatbotService.messages.last.isUser;
        } else {
          _isTyping = false;
        }
      });
      
      // Scroll to bottom on new messages
      if (_chatbotService.messages.isNotEmpty) {
        _scrollToBottom();
      }
    }
  }

  /// Initialize chat: check cache or fetch history
  Future<void> _initializeChat() async {
    if (_chatbotService.hasLoadedHistory) {
      setState(() => _isLoadingHistory = false);
      if (_chatbotService.messages.isNotEmpty) _scrollToBottom();
    } else {
      await _loadHistory();
    }
  }

  /// Load chat history from service
  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    
    try {
      await _chatbotService.loadHistory();
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        Helpers.showError(context, 'Failed to sync chat history');
      }
    }
  }
  
  /// Send message
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageText = text.trim();
    _messageController.clear();

    // We don't manually add to a local list anymore.
    // We call the service, which updates its list and notifies us.
    
    try {
      await _chatbotService.sendMessage(messageText);
    } catch (e) {
      if (mounted) {
        // The service has already removed the message from the list
        Helpers.showError(context, "Failed to send message. Please try again.");
      }
    }
  }

  /// Scroll to bottom
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
    final messages = _chatbotService.messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isLoadingHistory ? null : () async {
              await _chatbotService.clearHistory();
            },
            tooltip: 'Clear History',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About AI Assistant',
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested questions (only show if history is empty)
          if (!_isLoadingHistory && messages.isEmpty) 
            _buildSuggestedQuestions(),
          
          // Chat messages area
          Expanded(
            child: _isLoadingHistory
                ? _buildLoadingState()
                : messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(messages),
          ),
          
          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Syncing conversation history...',
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
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
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
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }
  
  /// Build single message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: message.isUser
                          ? Colors.white
                          : AppTheme.textPrimaryColor,
                      height: 1.4,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build typing indicator
  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
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
        ],
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
  Widget _buildInputArea() {
    // Disable input while loading history
    final isEnabled = !_isLoadingHistory;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: SafeArea(
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
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderColor),
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
