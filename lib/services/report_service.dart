import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/models/report.dart';
import 'package:madadgar/services/user_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'reports';
  final UserService _userService = UserService();

  // Submit a report for a post
  Future<void> reportPost({
    required String postId,
    required String reportedUserId,
    required ReportType type,
    required String description,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get reporter's name
      final reporterName = await _userService.getUsername(currentUser.uid);

      // Check if user has already reported this post
      final existingReport = await _firestore
          .collection(_collectionName)
          .where('postId', isEqualTo: postId)
          .where('reporterId', isEqualTo: currentUser.uid)
          .get();

      if (existingReport.docs.isNotEmpty) {
        throw Exception('You have already reported this post');
      }

      // Create new report
      final docRef = _firestore.collection(_collectionName).doc();
      final report = ReportModel(
        id: docRef.id,
        postId: postId,
        reporterId: currentUser.uid,
        reporterName: reporterName,
        reportedUserId: reportedUserId,
        type: type,
        description: description,
        createdAt: DateTime.now(),
      );

      await docRef.set(report.toMap());
      print('Report submitted successfully');
    } catch (e) {
      print("Error submitting report: $e");
      rethrow;
    }
  }

  // Check if current user has reported a specific post
  Future<bool> hasUserReportedPost(String postId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final query = await _firestore
          .collection(_collectionName)
          .where('postId', isEqualTo: postId)
          .where('reporterId', isEqualTo: currentUser.uid)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print("Error checking if user reported post: $e");
      return false;
    }
  }

  // Get all reports for a specific post
  Future<List<ReportModel>> getReportsForPost(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ReportModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting reports for post: $e");
      rethrow;
    }
  }

  // Get report count for a post
  Future<int> getReportCountForPost(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('postId', isEqualTo: postId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print("Error getting report count: $e");
      return 0;
    }
  }

  // Get all unresolved reports (for admin use)
  Future<List<ReportModel>> getUnresolvedReports() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isResolved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ReportModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting unresolved reports: $e");
      rethrow;
    }
  }

  // Mark report as resolved (for admin use)
  Future<void> resolveReport(String reportId, String adminNotes) async {
    try {
      await _firestore.collection(_collectionName).doc(reportId).update({
        'isResolved': true,
        'adminNotes': adminNotes,
      });
    } catch (e) {
      print("Error resolving report: $e");
      rethrow;
    }
  }

  // Delete a report
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection(_collectionName).doc(reportId).delete();
    } catch (e) {
      print("Error deleting report: $e");
      rethrow;
    }
  }
}
