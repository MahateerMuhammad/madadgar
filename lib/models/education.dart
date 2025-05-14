import 'package:cloud_firestore/cloud_firestore.dart';

class EducationalResourceModel {
  final String id;
  final String title;
  final String description;
  final String resourceUrl;
  final String thumbnailUrl;
  final String fileType; // pdf, doc, ppt, video, image, etc.
  final String category; // e.g., Mathematics, Science, History
  final String subCategory; // e.g., Algebra, Biology, World War II
  final String uploaderId;
  final String uploaderName;
  final int downloadCount;
  final int likeCount;
  final List<String> tags;
  final bool isVerified; // For curated content
  final DateTime createdAt;
  final DateTime updatedAt;

  EducationalResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.resourceUrl,
    this.thumbnailUrl = '',
    required this.fileType,
    required this.category,
    this.subCategory = '',
    required this.uploaderId,
    required this.uploaderName,
    this.downloadCount = 0,
    this.likeCount = 0,
    this.tags = const [],
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'resourceUrl': resourceUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileType': fileType,
      'category': category,
      'subCategory': subCategory,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'downloadCount': downloadCount,
      'likeCount': likeCount,
      'tags': tags,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map from Firebase
  factory EducationalResourceModel.fromMap(Map<String, dynamic> map) {
    return EducationalResourceModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      resourceUrl: map['resourceUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      fileType: map['fileType'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      uploaderId: map['uploaderId'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      downloadCount: map['downloadCount'] ?? 0,
      likeCount: map['likeCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  // Copy with new values
  EducationalResourceModel copyWith({
    String? title,
    String? description,
    String? resourceUrl,
    String? thumbnailUrl,
    String? fileType,
    String? category,
    String? subCategory,
    String? uploaderName,
    int? downloadCount,
    int? likeCount,
    List<String>? tags,
    bool? isVerified,
  }) {
    return EducationalResourceModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileType: fileType ?? this.fileType,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      uploaderId: uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      downloadCount: downloadCount ?? this.downloadCount,
      likeCount: likeCount ?? this.likeCount,
      tags: tags ?? this.tags,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}