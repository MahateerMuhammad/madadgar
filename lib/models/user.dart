class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String region;
  final String profileImage;
  final int helpCount; // Number of helps provided
  final int thankCount; // Number of thanks received
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.region,
    this.profileImage = '',
    this.helpCount = 0,
    this.thankCount = 0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'region': region,
      'profileImage': profileImage,
      'helpCount': helpCount,
      'thankCount': thankCount,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  // Create from Map from Firebase
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      region: map['region'],
      profileImage: map['profileImage'] ?? '',
      helpCount: map['helpCount'] ?? 0,
      thankCount: map['thankCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
  
  // Copy with new values
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? region,
    String? profileImage,
    int? helpCount,
    int? thankCount,
    bool? isVerified,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      profileImage: profileImage ?? this.profileImage,
      helpCount: helpCount ?? this.helpCount,
      thankCount: thankCount ?? this.thankCount,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}