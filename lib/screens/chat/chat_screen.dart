import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/models/chat.dart';
import 'package:madadgar/services/chat_service.dart';
import 'package:madadgar/models/post.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final PostModel? post;

  const ChatScreen({
    Key? key,
    required this.conversation,
    this.post,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = false;
  
  // Add a mutable copy of the conversation to track state changes
  late ChatConversation _currentConversation;
  
   bool _isAnonymousChat = false;

  @override
  void initState() {
    super.initState();
    // Initialize the mutable conversation with the widget's conversation
    _currentConversation = widget.conversation;
    
    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _determineAnonymity();

      _markMessagesAsRead();
    });
  }

    // Add this method to determine if chat should be anonymous
  void _determineAnonymity() {
    // If post is provided, check its anonymous property
    if (widget.post != null) {
      _isAnonymousChat = widget.post!.isAnonymous;
      return;
    }
    
    // If post isn't available, infer from conversation data
    // If userName2 is "Anonymous", likely this was an anonymous post
    if (_currentConversation.userName2 == "Anonymous") {
      _isAnonymousChat = true;
    }
  }

  
  void _markMessagesAsRead() {
    _chatService.markAsRead(_currentConversation);
  }

  // Check if chat is completed (help given, thanks given, or marked as fulfilled)
  bool get _isChatCompleted {
    return _currentConversation.isFulfilled || 
           _currentConversation.helpGivenByUser1 || 
           _currentConversation.helpGivenByUser2 ||
           _currentConversation.thanksGivenByUser1 || 
           _currentConversation.thanksGivenByUser2;
  }


 // Change this method in ChatScreen.dart (inside _ChatScreenState class)
@override
Widget build(BuildContext context) {
  final bool isPostCreator = _currentUserId == _currentConversation.userId1;
  final bool isNeedPost = _currentConversation.postType == 'need';
  
  // FIXED LOGIC: For Need posts, only the post creator (userId1) can give help
  // For Offer posts, only the responder (userId2) can give thanks
  final bool canGiveHelp = isNeedPost && isPostCreator;  
  final bool canGiveThanks = !isNeedPost && !isPostCreator;
  
  // Rest of build method remains unchanged
    
    // Check if help already given by this user
    final bool helpAlreadyGiven = isPostCreator ? 
                                _currentConversation.helpGivenByUser1 : 
                                _currentConversation.helpGivenByUser2;
                                
    // Check if thanks already given by this user
    final bool thanksAlreadyGiven = isPostCreator ? 
                                  _currentConversation.thanksGivenByUser1 : 
                                  _currentConversation.thanksGivenByUser2;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPostCreator 
                  ? _currentConversation.userName2 
                  : _currentConversation.userName1,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              _currentConversation.postTitle,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
       actions: [
  // Only show the "Give Help" button if the current user is allowed to give help
  if (canGiveHelp && !_isChatCompleted && !helpAlreadyGiven)
    IconButton(
      icon: const Icon(Icons.volunteer_activism),
      tooltip: 'Give Help',
      onPressed: _giveHelp,
    ),

  // Only show the "Give Thanks" button if the current user is allowed to give thanks
  if (canGiveThanks && !_isChatCompleted && !thanksAlreadyGiven)
    IconButton(
      icon: const Icon(Icons.favorite),
      tooltip: 'Give Thanks',
      onPressed: _giveThanks,
    ),

  PopupMenuButton(
    itemBuilder: (context) => [
      if (!_isChatCompleted)
        PopupMenuItem(
          value: 'fulfill',
          child: const Text('Mark as Fulfilled'),
        ),
      PopupMenuItem(
        value: 'delete',
        child: const Text('Delete Conversation'),
      ),
    ],
    onSelected: (value) {
      if (value == 'fulfill') {
        _markAsFulfilled();
      } else if (value == 'delete') {
        _deleteConversation();
      }
    },
  ),
],


      ),
      body: Column(
        children: [
          // Status indicator for chat state
          if (_isChatCompleted)
            Container(
              color: Colors.green[100],
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              child: Center(
                child: Text(
                  _getCompletionStatusMessage(),
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(_currentConversation.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == _currentUserId;
                    final isSystemMessage = message.isSystem;
                    
                    if (isSystemMessage) {
                      // Display system messages centered with a different style
                      return Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return Align(
                      alignment: isCurrentUser 
                          ? Alignment.centerRight 
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrentUser 
                              ? Theme.of(context).primaryColor.withOpacity(0.8) 
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Text(
                                message.senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              message.message,
                              style: TextStyle(
                                color: isCurrentUser ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isCurrentUser 
                                    ? Colors.white70 
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input - only show if conversation is not completed
          if (!_isChatCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          
          // Show message that chat is completed
          if (_isChatCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              width: double.infinity,
              child: const Text(
                'This conversation has been completed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Get appropriate status message based on conversation state
  String _getCompletionStatusMessage() {
    if (_currentConversation.helpGivenByUser1) {
      return '${_currentConversation.userName1} has provided help';
    } else if (_currentConversation.helpGivenByUser2) {
      return '${_currentConversation.userName2} has provided help';
    } else if (_currentConversation.thanksGivenByUser1) {
      return '${_currentConversation.userName1} has given thanks';
    } else if (_currentConversation.thanksGivenByUser2) {
      return '${_currentConversation.userName2} has given thanks';
    } else if (_currentConversation.isFulfilled) {
      return 'This request has been fulfilled';
    }
    return 'This conversation is completed';
  }

 // In ChatScreen class (_ChatScreenState), we can simplify the sendMessage method 
// since ChatService will now handle anonymity

Future<void> _sendMessage() async {
  final message = _messageController.text.trim();
  if (message.isEmpty) return;

  setState(() {
    _isLoading = true;
  });

  try {
    // Get sender name from conversation without worrying about anonymity
    // The ChatService will handle applying anonymity if needed
    final senderName = _currentUserId == _currentConversation.userId1
        ? _currentConversation.userName1
        : _currentConversation.userName2;

    await _chatService.sendMessage(
      conversationId: _currentConversation.id,
      message: message,
      senderName: senderName, // ChatService will apply anonymity if needed
    );

    _messageController.clear();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sending message: ${e.toString()}')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<void> _giveHelp() async {
    try {
      await _chatService.giveHelp(_currentConversation);
      
      // Refresh conversation data
      final updated = await _chatService.getConversationById(_currentConversation.id);
      
      // Update the local state with the updated conversation
      setState(() {
        _currentConversation = updated;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Help recorded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error giving help: ${e.toString()}')),
      );
    }
  }

  Future<void> _giveThanks() async {
    try {
      await _chatService.giveThanks(_currentConversation);
      
      // Refresh conversation data
      final updated = await _chatService.getConversationById(_currentConversation.id);
      
      // Update the local state with the updated conversation
      setState(() {
        _currentConversation = updated;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks recorded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error giving thanks: ${e.toString()}')),
      );
    }
  }

  Future<void> _markAsFulfilled() async {
    try {
      await _chatService.markAsFulfilled(_currentConversation.id);
      
      // Refresh conversation data
      final updated = await _chatService.getConversationById(_currentConversation.id);
      
      // Update local state to reflect fulfillment status
      setState(() {
        _currentConversation = updated;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as fulfilled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking as fulfilled: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _chatService.deleteConversation(_currentConversation.id);
        Navigator.pop(context); // Go back to previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting conversation: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      // Today, show time only
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days, show date and time
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}