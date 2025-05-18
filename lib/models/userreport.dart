import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  pending,
  reviewing,
  resolved,
  dismissed
}

class UserReportModel {
  final String? id;
  final String reporterId; // User who submitted the report
  final String reportedUserId; // User being reported
  final String reason;
  final String description;
  final List<String> imageUrls; // URLs of uploaded images
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserReportModel({
    this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    this.imageUrls = const [],
    this.status = ReportStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description,
      'imageUrls': imageUrls,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map from Firebase
  factory UserReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserReportModel(
      id: docId,
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: _parseReportStatus(map['status']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Parse ReportStatus from string
  static ReportStatus _parseReportStatus(String? status) {
    switch (status) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewing':
        return ReportStatus.reviewing;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }

  // Create a copy with modified fields
  UserReportModel copyWith({
    String? reason,
    String? description,
    List<String>? imageUrls,
    ReportStatus? status,
  }) {
    return UserReportModel(
      id: id,
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}