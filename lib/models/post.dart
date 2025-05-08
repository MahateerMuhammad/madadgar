enum PostType { need, offer }
enum PostStatus { active, fulfilled, closed }

class PostModel {
  final String id;
  final String userId;
  final String userName; // Cached for display
  final String userImage; // Cached for display
  final PostType type;
  final String title;
  final String description;
  final String category;
  final String region;
  final bool isAnonymous;
  final List<String> images;
  final PostStatus status;
  final int viewCount;
  final int respondCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage = '',
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.region,
    this.isAnonymous = false,
    this.images = const [],
    this.status = PostStatus.active,
    this.viewCount = 0,
    this.respondCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'category': category,
      'region': region,
      'isAnonymous': isAnonymous,
      'images': images,
      'status': status.toString().split('.').last,
      'viewCount': viewCount,
      'respondCount': respondCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  // Create from Map from Firebase
  factory PostModel.fromMap(Map<String, dynamic> map) {
    try {
      return PostModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        userImage: map['userImage'] ?? '',
        type: map['type'] == 'need' ? PostType.need : PostType.offer,
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        category: map['category'] ?? '',
        region: map['region'] ?? '',
        isAnonymous: map['isAnonymous'] ?? false,
        images: List<String>.from(map['images'] ?? []),
        status: _mapStringToStatus(map['status']),
        viewCount: map['viewCount'] ?? 0,
        respondCount: map['respondCount'] ?? 0,
        createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      print("Error mapping post data: $e");
      rethrow;  // This ensures the error is passed up the call stack
    }
  }
  
  static PostStatus _mapStringToStatus(String? status) {
    switch (status) {
      case 'fulfilled':
        return PostStatus.fulfilled;
      case 'closed':
        return PostStatus.closed;
      case 'active':
      default:
        return PostStatus.active;
    }
  }
  
  // Copy with new values
  PostModel copyWith({
    String? title,
    String? description,
    String? category,
    String? region,
    bool? isAnonymous,
    List<String>? images,
    PostStatus? status,
    int? viewCount,
    int? respondCount, required String id,
  }) {
    return PostModel(
      id: this.id,
      userId: userId,
      userName: userName,
      userImage: userImage,
      type: type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      region: region ?? this.region,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      images: images ?? this.images,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      respondCount: respondCount ?? this.respondCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
