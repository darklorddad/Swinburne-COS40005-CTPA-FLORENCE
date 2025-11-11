import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../core/config/environment.dart';
import '../services/chatbot_service.dart';

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
  final _chatbotService = ChatbotService();
  bool _isTyping = false;

  // Chat messages
  final List<ChatMessage> _messages = [];

  // Suggested questions (will be updated from service)
  List<String> _suggestedQuestions = [];
  
  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _loadSuggestedQuestions();
  }

  /// Load suggested questions from service
  void _loadSuggestedQuestions() {
    setState(() {
      _suggestedQuestions = _chatbotService.getSuggestedQuestions();
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  /// Add welcome message
  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: "Hi! I'm your AI Health Assistant 👋\n\nI can help you understand your glucose patterns, suggest meal ideas, answer health questions, and provide personalized recommendations.\n\nWhat would you like to know?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }
  
  /// Send message
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(
          text: text.trim(),
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isTyping = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Get AI response from chatbot service
      final response = await _chatbotService.sendMessage(text.trim());

      // Add AI response
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: response.content,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();

        // Update suggested questions based on context
        _loadSuggestedQuestions();
      }
    } catch (e) {
      // If AI fails, use fallback response
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "I'm having trouble connecting to the AI service right now. Please check your internet connection. In the meantime, you can:\n\n• View your trends and patterns\n• Check your recommendations\n• Log your health data\n\nError: ${e.toString()}",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About AI Assistant',
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested questions
          if (_messages.length <= 1) _buildSuggestedQuestions(),
          
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
          
          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),
          
          // Input area
          _buildInputArea(),
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
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
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
                message.text,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: SafeArea(
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
                          hintText: 'Ask me anything...',
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

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}