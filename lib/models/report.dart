enum ReportType {
  spam,
  inappropriate,
  harassment,
  scam,
  violence,
  falseInformation,
  other
}

class ReportModel {
  final String id;
  final String postId;
  final String reporterId;
  final String reporterName;
  final String reportedUserId;
  final ReportType type;
  final String description;
  final DateTime createdAt;
  final bool isResolved;
  final String? adminNotes;

  ReportModel({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserId,
    required this.type,
    required this.description,
    required this.createdAt,
    this.isResolved = false,
    this.adminNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'type': type.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
      'adminNotes': adminNotes,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'],
      postId: map['postId'],
      reporterId: map['reporterId'],
      reporterName: map['reporterName'],
      reportedUserId: map['reportedUserId'],
      type: ReportType.values.firstWhere((e) => e.name == map['type']),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      isResolved: map['isResolved'] ?? false,
      adminNotes: map['adminNotes'],
    );
  }

  ReportModel copyWith({
    String? id,
    String? postId,
    String? reporterId,
    String? reporterName,
    String? reportedUserId,
    ReportType? type,
    String? description,
    DateTime? createdAt,
    bool? isResolved,
    String? adminNotes,
  }) {
    return ReportModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
