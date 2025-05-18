import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/models/userreport.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class UserReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = 'user_reports';
  
  // Cloudinary configuration
  final String cloudName = "ddppfyrcv";
  final String presetName = "madadgar";
  final String uploadUrl = "https://api.cloudinary.com/v1_1/ddppfyrcv/image/upload";
  final Dio _dio = Dio();

  // Create a new report
  Future<String> createReport({
    required String reportedUserId,
    required String reason,
    required String description,
    List<File> images = const [],
  }) async {
    try {
      // Get current user ID
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload images to Cloudinary
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await uploadImagesToCloudinary(images);
      }

      // Create report model
      final report = UserReportModel(
        reporterId: currentUser.uid,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        imageUrls: imageUrls,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(_collectionName)
          .add(report.toMap());

      return docRef.id;
    } catch (e) {
      print("Error creating report: $e");
      rethrow;
    }
  }

  // Upload images to Cloudinary
  Future<List<String>> uploadImagesToCloudinary(List<File> images) async {
    List<String> uploadedUrls = [];

    try {
      for (var image in images) {
        // Get file extension
        String extension = image.path.split('.').last.toLowerCase();
        String mimeType;

        // Determine MIME type
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          default:
            mimeType = 'image/jpeg'; // Default
        }

        // Prepare form data for upload
        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            image.path,
            contentType: MediaType.parse(mimeType),
          ),
          'upload_preset': presetName,
        });

        // Upload to Cloudinary
        final response = await _dio.post(
          uploadUrl,
          data: formData,
        );

        if (response.statusCode == 200) {
          // Extract URL from response
          String imageUrl = response.data['secure_url'];
          uploadedUrls.add(imageUrl);
        } else {
          throw Exception('Failed to upload image to Cloudinary');
        }
      }
      return uploadedUrls;
    } catch (e) {
      print("Error uploading images to Cloudinary: $e");
      rethrow;
    }
  }

  // Get all reports for a specific user being reported
  Future<List<UserReportModel>> getReportsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('reportedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return UserReportModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print("Error getting reports for user: $e");
      rethrow;
    }
  }

  // Get all reports made by the current user
  Future<List<UserReportModel>> getReportsByCurrentUser() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('reporterId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return UserReportModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print("Error getting reports by current user: $e");
      rethrow;
    }
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      await _firestore.collection(_collectionName).doc(reportId).update({
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error updating report status: $e");
      rethrow;
    }
  }

  // Get a single report by ID
  Future<UserReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(reportId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return UserReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print("Error getting report by ID: $e");
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