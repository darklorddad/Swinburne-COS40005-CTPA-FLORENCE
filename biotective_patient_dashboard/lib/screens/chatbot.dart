import 'package:flutter/material.dart';

// --- Main Chatbot Screen Widget --- //

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // A list to hold mock chat messages
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi Tom, I'm your AI health assistant. How can I help you today?",
      isUser: false,
    ),
  ];

  final TextEditingController _textController = TextEditingController();

  // Function to handle sending a message
  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      // Simulate a bot response
      _receiveBotResponse(text);
    });
  }
  
  // A simple mock function to simulate a bot response based user input
  void _receiveBotResponse(String userMessage) {
    String botResponse;
    if (userMessage.toLowerCase().contains('glucose') && userMessage.toLowerCase().contains('high')) {
       botResponse = "Looking at your data, your glucose peaked at 12.5 mmol/L after your dinner yesterday, which included a cheeseburger. Foods with refined carbohydrates can often cause a sharp spike.";
    } else if (userMessage.toLowerCase().contains('summarize')) {
       botResponse = "This past week, your average glucose was 11.2 mmol/L with 3 notable spikes. You've completed 120 of your 150-minute activity goal. Keep up the great work!";
    } else {
       botResponse = "I can help with questions about your health data, suggest meals, or summarize your progress. What would you like to know?";
    }
    
    // Insert the bot's message after a short delay to feel more natural
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _messages.insert(0, ChatMessage(text: botResponse, isUser: false));
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // The list of messages will take up most of the screen
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              reverse: true, // This makes the list start from the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          // A divider for a clean separation
          const Divider(height: 1.0),
          // The input area at the bottom
          _buildTextComposer(),
        ],
      ),
    );
  }

  // The text input field and suggestion chips
  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Suggestion chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSuggestionChip('Summarize my week'),
                _buildSuggestionChip('Why was my glucose high?'),
                _buildSuggestionChip('Suggest a healthy lunch'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // The actual text input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Type your message here...',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper widget for suggestion chips
  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        label: Text(text),
        onPressed: () => _handleSubmitted(text),
        backgroundColor: Colors.grey[700],
      ),
    );
  }
}

// --- Reusable Chat Message Widget --- //

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Display bot avatar for bot messages
          if (!isUser) ...[
            const CircleAvatar(child: Icon(Icons.support_agent)),
            const SizedBox(width: 12),
          ],
          // The message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser ? Theme.of(context).primaryColorLight : Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(text, style: const TextStyle(color: Colors.black87)),
            ),
          ),
          // Display user avatar for user messages
          if (isUser) ...[
            const SizedBox(width: 12),
            const CircleAvatar(child: Icon(Icons.person)),
          ],
        ],
      ),
    );
  }
}