import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final String postId;
  final String postTitle;
  final String postType;
  final String userId1;  // Post owner
  final String userName1;
  final String userId2;  // Responder
  final String userName2;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount1;
  final int unreadCount2;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFulfilled;
  final bool helpGivenByUser1;
  final bool helpGivenByUser2;
  final bool thanksGivenByUser1;
  final bool thanksGivenByUser2;

  ChatConversation({
    required this.id,
    required this.postId,
    required this.postTitle,
    required this.postType,
    required this.userId1,
    required this.userName1,
    required this.userId2,
    required this.userName2,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount1,
    required this.unreadCount2,
    required this.createdAt,
    required this.updatedAt,
    required this.isFulfilled,
    required this.helpGivenByUser1,
    required this.helpGivenByUser2,
    required this.thanksGivenByUser1,
    required this.thanksGivenByUser2,
  });

  factory ChatConversation.fromMap(String id, Map<String, dynamic> map) {
    // Handle Firestore timestamps
    Timestamp? lastMessageTimeTimestamp = map['lastMessageTime'] as Timestamp?;
    Timestamp? createdAtTimestamp = map['createdAt'] as Timestamp?;
    Timestamp? updatedAtTimestamp = map['updatedAt'] as Timestamp?;
    
    return ChatConversation(
      id: id,
      postId: map['postId'] ?? '',
      postTitle: map['postTitle'] ?? '',
      postType: map['postType'] ?? '',
      userId1: map['userId1'] ?? '',
      userName1: map['userName1'] ?? '',
      userId2: map['userId2'] ?? '',
      userName2: map['userName2'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: lastMessageTimeTimestamp?.toDate() ?? DateTime.now(),
      unreadCount1: map['unreadCount1'] ?? 0,
      unreadCount2: map['unreadCount2'] ?? 0,
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
      updatedAt: updatedAtTimestamp?.toDate() ?? DateTime.now(),
      isFulfilled: map['isFulfilled'] ?? false,
      helpGivenByUser1: map['helpGivenByUser1'] ?? false,
      helpGivenByUser2: map['helpGivenByUser2'] ?? false,
      thanksGivenByUser1: map['thanksGivenByUser1'] ?? false,
      thanksGivenByUser2: map['thanksGivenByUser2'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'postTitle': postTitle,
      'postType': postType,
      'userId1': userId1,
      'userName1': userName1,
      'userId2': userId2,
      'userName2': userName2,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount1': unreadCount1,
      'unreadCount2': unreadCount2,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFulfilled': isFulfilled,
      'helpGivenByUser1': helpGivenByUser1,
      'helpGivenByUser2': helpGivenByUser2,
      'thanksGivenByUser1': thanksGivenByUser1,
      'thanksGivenByUser2': thanksGivenByUser2,
    };
  }

  // Create a copy of this conversation with specified fields updated
  ChatConversation copyWith({
    String? postId,
    String? postTitle,
    String? postType,
    String? userId1,
    String? userName1,
    String? userId2,
    String? userName2,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount1,
    int? unreadCount2,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFulfilled,
    bool? helpGivenByUser1,
    bool? helpGivenByUser2,
    bool? thanksGivenByUser1,
    bool? thanksGivenByUser2,
  }) {
    return ChatConversation(
      id: this.id,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      postType: postType ?? this.postType,
      userId1: userId1 ?? this.userId1,
      userName1: userName1 ?? this.userName1,
      userId2: userId2 ?? this.userId2,
      userName2: userName2 ?? this.userName2,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount1: unreadCount1 ?? this.unreadCount1,
      unreadCount2: unreadCount2 ?? this.unreadCount2,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFulfilled: isFulfilled ?? this.isFulfilled,
      helpGivenByUser1: helpGivenByUser1 ?? this.helpGivenByUser1,
      helpGivenByUser2: helpGivenByUser2 ?? this.helpGivenByUser2,
      thanksGivenByUser1: thanksGivenByUser1 ?? this.thanksGivenByUser1,
      thanksGivenByUser2: thanksGivenByUser2 ?? this.thanksGivenByUser2,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.isSystem = false,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    // Handle Firestore timestamp
    Timestamp? timestampObj = map['timestamp'] as Timestamp?;
    
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: timestampObj?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      isSystem: map['isSystem'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isSystem': isSystem,
    };
  }
}