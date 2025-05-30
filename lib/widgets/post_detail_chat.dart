// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/services/chat_service.dart';
import 'package:madadgar/services/user_service.dart'; // Make sure to import UserService
import 'package:madadgar/screens/chat/chat_screen.dart';

class PostDetailChatWidget extends StatefulWidget {
  final PostModel post;

  const PostDetailChatWidget({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _PostDetailChatWidgetState createState() => _PostDetailChatWidgetState();
}

class _PostDetailChatWidgetState extends State<PostDetailChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService(); // Add UserService
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentUserId;
  late String _currentUserName;
  bool _isLoadingUsername = true; // Add this flag

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    _currentUserName = 'User'; // Default value
    _loadCurrentUsername(); // Call method to load actual username
  }

  // Method to load the actual username from Firestore
  Future<void> _loadCurrentUsername() async {
    if (_currentUserId.isEmpty) return;
    
    setState(() {
      _isLoadingUsername = true;
    });
    
    try {
      // Get username from UserService
      String username = await _userService.getCurrentUsername();
      
      if (mounted) {
        setState(() {
          _currentUserName = username;
          _isLoadingUsername = false;
        });
      }
      
      debugPrint("Loaded current username: $_currentUserName");
    } catch (e) {
      debugPrint("Error loading username: $e");
      if (mounted) {
        setState(() {
          _isLoadingUsername = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if viewing own post
    if (widget.post.userId == _currentUserId) {
      // Show a SnackBar and navigate back to the previous screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot reply to your own post')),
        );

        // Navigate back to the previous screen after showing the SnackBar
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      });
      return const SizedBox.shrink(); // Don't show the chat widget
    }

    // Show loading while fetching username
    if (_isLoadingUsername) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message to Post Owner',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _respondToPost,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToPost() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
          "Attempting to start conversation for post: ${widget.post.id}");
      debugPrint("Current user name being sent: $_currentUserName");

      // Start a conversation or add to existing one
      final conversation = await _chatService.startConversation(
        postId: widget.post.id,
        postTitle: widget.post.title,
        postType: widget.post.type.name,
        postOwnerId: widget.post.userId,
        postOwnerName: widget.post.userName,
        responderMessage: message,
        responderUserId: _currentUserId,    // Explicitly pass current user ID
        responderUserName: _currentUserName, // Pass the correct username
        isPostAnonymous: widget.post.isAnonymous,
      );

      debugPrint("Conversation created/retrieved: ${conversation.id}");

      // Clear the text field
      _messageController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );

      // Make sure we're using the most updated conversation object
      final updatedConversation =
          await _chatService.getConversationById(conversation.id);
      debugPrint("Fetched updated conversation: ${updatedConversation.id}");

      // Check if widget is still mounted before navigating
      if (!mounted) {
        debugPrint("Widget no longer mounted, skipping navigation");
        return;
      }

      debugPrint("Navigating to chat screen");

      // Use push instead of pushReplacement to maintain navigation stack
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversation: updatedConversation,
            post: widget.post,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error in _respondToPost: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}