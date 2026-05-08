import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:madadgar/models/chat.dart';
import 'package:madadgar/services/user_service.dart'; // Add this import

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService(); // Add UserService

  // Get current user data
  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? 'Anonymous';

  // Collection references
  CollectionReference get _conversationsRef =>
      _firestore.collection('conversations');
  CollectionReference _messagesRef(String conversationId) =>
      _firestore.collection('conversations/$conversationId/messages');
  CollectionReference get _respondedPostsRef =>
      _firestore.collection('respondedPosts'); // New collection for tracking responses

  Stream<List<ChatConversation>> getUserConversations() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return ChatConversation.fromMap(doc.id, doc.data());
            }).toList());
  }

  // Check if user has already responded to this post
  Future<bool> hasUserRespondedToPost(String postId, String userId) async {
    try {
      final response = await _respondedPostsRef
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();
      
      return response.docs.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking if user responded to post: $e");
      return false; // Assume not responded in case of error
    }
  }

  // Record that user has responded to a post
  Future<void> recordPostResponse(String postId, String userId) async {
    try {
      await _respondedPostsRef.add({
        'postId': postId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("Recorded that user $userId responded to post $postId");
    } catch (e) {
      debugPrint("Error recording post response: $e");
      // Still continue even if this fails
    }
  }

  // Start or get existing conversation
// Fix for the startConversation method in ChatService class
// Replace the existing method with this corrected version

// In ChatService class
// Fix for the startConversation method in ChatService class
// Replace the existing method with this corrected version

// Fix for the startConversation method in ChatService class
// Replace the existing method with this corrected version

Future<ChatConversation> startConversation({
  required String postId,
  required String postTitle,
  required String postType,
  required String postOwnerId,
  required String postOwnerName,
  required String responderMessage,
  required String responderUserId,      // Explicitly accept responder's ID
  required String responderUserName,    // Explicitly accept responder's name
  required bool isPostAnonymous,
}) async {
  if (responderUserId.isEmpty) {
    throw Exception('User must be logged in');
  }
  
  debugPrint("Starting conversation: Post ID: $postId, User1: $postOwnerId, User2: $responderUserId");
  debugPrint("Post Owner: $postOwnerName, Responder: $responderUserName, Anonymous: $isPostAnonymous");

  // Check if user has already responded to this post
  bool alreadyResponded = await hasUserRespondedToPost(postId, responderUserId);
  if (alreadyResponded) {
    throw Exception('You have already responded to this post');
  }

  // Check if conversation already exists
  QuerySnapshot existingConversations;
  try {
    existingConversations = await _conversationsRef
        .where('postId', isEqualTo: postId)
        .where('userId2', isEqualTo: responderUserId)
        .limit(1)
        .get();

    debugPrint(
        "Found ${existingConversations.docs.length} existing conversations");
  } catch (e) {
    debugPrint("Error checking for existing conversations: $e");
    throw Exception('Failed to check for existing conversations: $e');
  }

  late ChatConversation conversation;

  if (existingConversations.docs.isNotEmpty) {
    // Conversation exists, get it
    try {
      final doc = existingConversations.docs.first;
      conversation = ChatConversation.fromMap(
          doc.id, doc.data() as Map<String, dynamic>);

      debugPrint("Using existing conversation: ${conversation.id}");

      // Send the new message
      await sendMessage(
        conversationId: conversation.id,
        message: responderMessage,
        senderName: responderUserName,  // Use the provided username
      );
    } catch (e) {
      debugPrint("Error retrieving existing conversation: $e");
      throw Exception('Failed to retrieve existing conversation: $e');
    }
  } else {
    // Create new conversation
    try {
      // Store the real responder username regardless of anonymity setting
      // The sendMessage method will handle displaying "Anonymous" when appropriate
      final String actualResponderName = responderUserName;
      
      final conversationData = {
        'postId': postId,
        'postTitle': postTitle,
        'postType': postType,
        'userId1': postOwnerId, // Post owner
        'userName1': postOwnerName, // Post owner name
        'userId2': responderUserId, // Responder
        'userName2': actualResponderName, // Store real username in database
        'lastMessage': responderMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount1': 1, // Post owner has 1 unread message
        'unreadCount2': 0, // Responder has 0 unread
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isFulfilled': false,
        'helpGivenByUser1': false,
        'helpGivenByUser2': false,
        'thanksGivenByUser1': false,
        'thanksGivenByUser2': false,
        'participants': [
          postOwnerId,
          responderUserId
        ],
        'isAnonymous': isPostAnonymous, // Store the anonymity flag
      };

      debugPrint("Creating new conversation with data: $conversationData");

      // Create conversation document
      DocumentReference docRef =
          await _conversationsRef.add(conversationData);
      debugPrint("Created conversation with ID: ${docRef.id}");

      // Get the newly created conversation with server timestamps resolved
      DocumentSnapshot docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Newly created conversation document not found');
      }

      conversation = ChatConversation.fromMap(
          docRef.id, docSnapshot.data() as Map<String, dynamic>);

      debugPrint(
          "Successfully created and retrieved conversation: ${conversation.id}");

      // Determine what name should appear for the sender in this first message
      String displayName = isPostAnonymous ? "Anonymous" : actualResponderName;
      
      // Add first message - Store actual name in database but display respecting anonymity
      await _messagesRef(docRef.id).add({
        'senderId': responderUserId,
        'senderName': displayName, // Use display name that respects anonymity
        'receiverId': postOwnerId,
        'message': responderMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Record that this user has responded to this post
      await recordPostResponse(postId, responderUserId);

      debugPrint("Added first message to conversation");
    } catch (e) {
      debugPrint("Error creating new conversation: $e");
      throw Exception('Failed to create new conversation: $e');
    }
  }

  return conversation;
}

// Fix for the sendMessage method in ChatService class
// Replace the existing method with this corrected version

Future<void> sendMessage({
  required String conversationId,
  required String message,
  required String senderName, // This may be modified if needed for anonymity
}) async {
  if (currentUserId.isEmpty) {
    throw Exception('User must be logged in');
  }

  // Check if conversation is completed
  bool isCompleted = await isConversationCompleted(conversationId);
  if (isCompleted) {
    throw Exception('This conversation has been completed and cannot receive new messages');
  }

  debugPrint("Sending message to conversation: $conversationId");

  // Get the conversation to determine who to send to and respect anonymity
  try {
    DocumentSnapshot conversationDoc =
        await _conversationsRef.doc(conversationId).get();

    if (!conversationDoc.exists) {
      debugPrint("Conversation not found with ID: $conversationId");
      throw Exception('Conversation not found');
    }

    Map<String, dynamic> conversationData =
        conversationDoc.data() as Map<String, dynamic>;

    String receiverId = conversationData['userId1'] == currentUserId
        ? conversationData['userId2']
        : conversationData['userId1'];

    // Check if this conversation is anonymous
    bool isAnonymousConversation = conversationData['isAnonymous'] == true;
    
    // Only apply anonymity for the responder (userId2)
    String effectiveSenderName = senderName;
    if (isAnonymousConversation && currentUserId == conversationData['userId2']) {
      effectiveSenderName = "Anonymous";
      debugPrint("Using anonymous sender name because conversation is anonymous and user is responder");
    }

    // Update unread count for the receiver
    String unreadField = conversationData['userId1'] == receiverId
        ? 'unreadCount1'
        : 'unreadCount2';

    debugPrint("Adding message from $currentUserId to $receiverId with name: $effectiveSenderName");

    // Add the message with the effective sender name
    await _messagesRef(conversationId).add({
      'senderId': currentUserId,
      'senderName': effectiveSenderName, // Use the anonymity-respecting name
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    debugPrint("Updating conversation metadata");

    // Update conversation metadata
    await _conversationsRef.doc(conversationId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      unreadField: FieldValue.increment(1),
    });

    debugPrint("Message sent successfully");
  } catch (e) {
    debugPrint("Error sending message: $e");
    throw Exception('Failed to send message: $e');
  }
}
  // Get a conversation by ID
  Future<ChatConversation> getConversationById(String conversationId) async {
    try {
      debugPrint("Fetching conversation with ID: $conversationId");
      DocumentSnapshot doc = await _conversationsRef.doc(conversationId).get();

      if (!doc.exists) {
        debugPrint("Conversation not found with ID: $conversationId");
        throw Exception('Conversation not found');
      }

      final conversation =
          ChatConversation.fromMap(doc.id, doc.data() as Map<String, dynamic>);

      debugPrint("Successfully retrieved conversation: ${conversation.id}");
      return conversation;
    } catch (e) {
      debugPrint("Error retrieving conversation: $e");
      throw Exception('Failed to retrieve conversation: $e');
    }
  }

  // Get messages from a conversation
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    debugPrint("Setting up messages stream for conversation: $conversationId");
    return _messagesRef(conversationId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      debugPrint("Received messages update. Count: ${snapshot.docs.length}");
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Check if conversation is completed (help or thanks given, or marked as fulfilled)
  Future<bool> isConversationCompleted(String conversationId) async {
    try {
      DocumentSnapshot doc = await _conversationsRef.doc(conversationId).get();
      if (!doc.exists) return false;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Check if post is fulfilled or help/thanks already given
      return data['isFulfilled'] == true || 
             data['helpGivenByUser1'] == true || 
             data['helpGivenByUser2'] == true ||
             data['thanksGivenByUser1'] == true || 
             data['thanksGivenByUser2'] == true;
    } catch (e) {
      debugPrint("Error checking if conversation is completed: $e");
      return false; // Default to allowing messages if check fails
    }
  }

  // Send a message - now checks if conversation is completed
  // In ChatService class, modify the sendMessage method to honor the anonymity setting
// Fix for the sendMessage method in ChatService class
// Replace the existing method with this corrected version

  // Mark conversation as read
  Future<void> markAsRead(ChatConversation conversation) async {
    try {
      String unreadField = conversation.userId1 == currentUserId
          ? 'unreadCount1'
          : 'unreadCount2';

      debugPrint(
          "Marking conversation ${conversation.id} as read for $unreadField");

      await _conversationsRef.doc(conversation.id).update({
        unreadField: 0,
      });

      debugPrint("Conversation marked as read");
    } catch (e) {
      debugPrint("Error marking conversation as read: $e");
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  // Modified: Give help in conversation and update user help count
// Fix the giveHelp method in ChatService.dart
Future<void> giveHelp(ChatConversation conversation) async {
  try {
    // For Need posts, only the post creator (userId1) can give help
    final isPostOwner = conversation.userId1 == currentUserId;
    final isNeedPost = conversation.postType == 'need';
    
    // Validate that this is a valid help action
    if (!(isNeedPost && isPostOwner)) {
      throw Exception('Only the creator of a need post can give help');
    }
    
    // The recipient is always userId2 (the responder)
    String helpRecipientId = conversation.userId2;
    
    debugPrint("Recording help given to $helpRecipientId in conversation ${conversation.id}");

    // Update the help given field - for need posts, the post creator gives help
    await _conversationsRef.doc(conversation.id).update({
      'helpGivenByUser1': true, // Post owner (userId1) marks that they've given help
      'isFulfilled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Increment the responder's helpCount
    await _userService.incrementHelpCount(helpRecipientId);
    debugPrint("Incremented help count for user $helpRecipientId");

    // Add system message
    await _messagesRef(conversation.id).add({
      'senderId': 'system',
      'senderName': 'System',
      'receiverId': 'all',
      'message': '${conversation.userName1} has marked that ${conversation.userName2} provided help',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'isSystem': true,
    });

    debugPrint("Help marked successfully and help count incremented");
  } catch (e) {
    debugPrint("Error marking help: $e");
    throw Exception('Failed to mark help: $e');
  }
}

// Fix the giveThanks method in ChatService.dart
Future<void> giveThanks(ChatConversation conversation) async {
  try {
    // For Offer posts, only the responder (userId2) can give thanks
    final isPostOwner = conversation.userId1 == currentUserId;
    final isNeedPost = conversation.postType == 'need';
    
    // Validate that this is a valid thanks action
    if (!((!isNeedPost) && (!isPostOwner))) {
      throw Exception('Only the responder to an offer post can give thanks');
    }
    
    // The recipient is always userId1 (the post creator)
    String thankedUserId = conversation.userId1;

    debugPrint("Recording thanks given to $thankedUserId in conversation ${conversation.id}");

    // Update the thanks given field - for offer posts, the responder gives thanks
    await _conversationsRef.doc(conversation.id).update({
      'thanksGivenByUser2': true, // Responder (userId2) marks that they've given thanks
      'isFulfilled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Increment the post creator's thankCount
    await _userService.incrementThankCount(thankedUserId);
    debugPrint("Incremented thank count for user $thankedUserId");

    // Add system message
    await _messagesRef(conversation.id).add({
      'senderId': 'system',
      'senderName': 'System',
      'receiverId': 'all',
      'message': '${conversation.userName2} says thank you to ${conversation.userName1}',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'isSystem': true,
    });

    debugPrint("Thanks recorded successfully and thank count incremented");
  } catch (e) {
    debugPrint("Error recording thanks: $e");
    throw Exception('Failed to record thanks: $e');
  }
}

  // Mark conversation as fulfilled
  Future<void> markAsFulfilled(String conversationId) async {
    try {
      debugPrint("Marking conversation $conversationId as fulfilled");

      // Update the 'isFulfilled' field in the conversation document
      await _conversationsRef.doc(conversationId).update({
        'isFulfilled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add a system message indicating fulfillment
      await _messagesRef(conversationId).add({
        'senderId': 'system',
        'senderName': 'System',
        'receiverId': 'all',
        'message': 'This request has been marked as fulfilled',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isSystem': true,
      });

      debugPrint("Conversation marked as fulfilled");
    } catch (e) {
      debugPrint("Error marking conversation as fulfilled: $e");
      throw Exception('Failed to mark conversation as fulfilled: $e');
    }
  }

  // Modified: Give thanks in conversation and update user thank count
  

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      debugPrint("Deleting conversation $conversationId");

      // Get all messages in the conversation
      QuerySnapshot messagesSnapshot = await _messagesRef(conversationId).get();

      // Use batch to delete all messages
      WriteBatch batch = _firestore.batch();

      // Add message deletions to batch
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add conversation deletion to batch
      batch.delete(_conversationsRef.doc(conversationId));

      // Commit batch
      await batch.commit();

      debugPrint("Conversation and all messages deleted successfully");
    } catch (e) {
      debugPrint("Error deleting conversation: $e");
      throw Exception('Failed to delete conversation: $e');
    }
  }
}