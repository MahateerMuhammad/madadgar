import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus { pending, approved, rejected }

class VerificationRequestModel {
  final String id;
  final String userId;
  final String cnicNumber;
  final String fullName;
  final String fatherOrHusbandName;
  final String dateOfBirth;
  final String issueDate;
  final String expiryDate;
  final String gender;
  final String cnicImageUrl;
  final String faceImageUrl;
  final VerificationStatus status;
  final String rejectionReason;
  final String reviewedBy;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  VerificationRequestModel({
    required this.id,
    required this.userId,
    this.cnicNumber = '',
    this.fullName = '',
    this.fatherOrHusbandName = '',
    this.dateOfBirth = '',
    this.issueDate = '',
    this.expiryDate = '',
    this.gender = '',
    this.cnicImageUrl = '',
    this.faceImageUrl = '',
    this.status = VerificationStatus.pending,
    this.rejectionReason = '',
    this.reviewedBy = '',
    required this.submittedAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cnicNumber': cnicNumber,
      'fullName': fullName,
      'fatherOrHusbandName': fatherOrHusbandName,
      'dateOfBirth': dateOfBirth,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'gender': gender,
      'cnicImageUrl': cnicImageUrl,
      'faceImageUrl': faceImageUrl,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'reviewedBy': reviewedBy,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  factory VerificationRequestModel.fromMap(Map<String, dynamic> map) {
    return VerificationRequestModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      cnicNumber: map['cnicNumber'] ?? '',
      fullName: map['fullName'] ?? '',
      fatherOrHusbandName: map['fatherOrHusbandName'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      issueDate: map['issueDate'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      gender: map['gender'] ?? '',
      cnicImageUrl: map['cnicImageUrl'] ?? '',
      faceImageUrl: map['faceImageUrl'] ?? '',
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VerificationStatus.pending,
      ),
      rejectionReason: map['rejectionReason'] ?? '',
      reviewedBy: map['reviewedBy'] ?? '',
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'])
          : DateTime.now(),
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.parse(map['reviewedAt'])
          : null,
    );
  }

  VerificationRequestModel copyWith({
    String? id,
    String? userId,
    String? cnicNumber,
    String? fullName,
    String? fatherOrHusbandName,
    String? dateOfBirth,
    String? issueDate,
    String? expiryDate,
    String? gender,
    String? cnicImageUrl,
    String? faceImageUrl,
    VerificationStatus? status,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  }) {
    return VerificationRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      fullName: fullName ?? this.fullName,
      fatherOrHusbandName: fatherOrHusbandName ?? this.fatherOrHusbandName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      gender: gender ?? this.gender,
      cnicImageUrl: cnicImageUrl ?? this.cnicImageUrl,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
