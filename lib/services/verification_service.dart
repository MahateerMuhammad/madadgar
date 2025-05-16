import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:madadgar/models/user.dart';
import 'package:madadgar/config/constants.dart';
import 'dart:io';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cloudinary configuration
  final String cloudName = "ddppfyrcv";
  final String presetName = "madadgar";
  final String uploadUrl = "https://api.cloudinary.com/v1_1/ddppfyrcv/image/upload";
  
  // Collection names
  final String _verificationCollection = 'verification_requests';
  final String _adminCollection = 'admins';
  
  // Verification status enum as string constants
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_APPROVED = 'approved';
  static const String STATUS_REJECTED = 'rejected';
  
  // Submit verification request
  Future<String> submitVerificationRequest({
    required String userId,
    required File idCardFront,
    required File idCardBack,
    required String cnic,
    String? additionalInfo,
  }) async {
    try {
      // Upload documents to Cloudinary
      final idFrontUrl = await uploadImageToCloudinary(idCardFront);
      final idBackUrl = await uploadImageToCloudinary(idCardBack);
      
      // Get user data
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
          
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = UserModel.fromMap(userDoc.data()!);
      
      // Create verification request document
      final requestId = _firestore.collection(_verificationCollection).doc().id;
      
      await _firestore.collection(_verificationCollection).doc(requestId).set({
        'userId': userId,
        'userName': userData.name,
        'userEmail': userData.email,
        'userPhone': userData.phone,
        'userRegion': userData.region,
        'idCardFrontUrl': idFrontUrl,
        'idCardBackUrl': idBackUrl,
        'cnicNumber': cnic,
        'additionalInfo': additionalInfo ?? '',
        'status': STATUS_PENDING,
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewNotes': '',
      });
      
      return requestId;
    } catch (e) {
      print('Error submitting verification request: $e');
      rethrow;
    }
  }
  
  // Upload image to Cloudinary
  Future<String> uploadImageToCloudinary(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields['upload_preset'] = presetName
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));
      
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonData = jsonDecode(responseString);
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload image: ${jsonData['error']}');
      }
      
      return jsonData['secure_url'];
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }
  
  // Check verification status
  Future<Map<String, dynamic>> checkVerificationStatus(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_verificationCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return {
          'hasSubmitted': false,
          'status': null,
          'submittedAt': null,
        };
      }
      
      final requestDoc = querySnapshot.docs.first;
      final requestData = requestDoc.data();
      
      return {
        'hasSubmitted': true,
        'requestId': requestDoc.id,
        'status': requestData['status'],
        'submittedAt': requestData['submittedAt'],
        'reviewedAt': requestData['reviewedAt'],
        'reviewNotes': requestData['reviewNotes'] ?? '',
      };
    } catch (e) {
      print('Error checking verification status: $e');
      rethrow;
    }
  }
  
  // Get all pending verification requests (for admin panel)
  Future<List<Map<String, dynamic>>> getAllVerificationRequests({
    String? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_verificationCollection)
          .orderBy('submittedAt', descending: true);
          
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting verification requests: $e');
      rethrow;
    }
  }
  
  // Get verification request details (for admin)
  Future<Map<String, dynamic>> getVerificationRequestDetails(String requestId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_verificationCollection)
          .doc(requestId)
          .get();
      
      if (!docSnapshot.exists) {
        throw Exception('Verification request not found');
      }
      
      return {
        'id': docSnapshot.id,
        ...docSnapshot.data()!
      };
    } catch (e) {
      print('Error getting verification request details: $e');
      rethrow;
    }
  }
  
  // Process verification request (for admin or automated system)
  Future<void> processVerificationRequest({
    required String requestId,
    required String status,
    String? reviewNotes,
  }) async {
    try {
      // Get the verification request
      final requestDoc = await _firestore
          .collection(_verificationCollection)
          .doc(requestId)
          .get();
      
      if (!requestDoc.exists) {
        throw Exception('Verification request not found');
      }
      
      final requestData = requestDoc.data()!;
      final userId = requestData['userId'];
      
      // Update the verification request status
      await _firestore.collection(_verificationCollection).doc(requestId).update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewNotes': reviewNotes ?? '',
      });
      
      // If approved, update the user's verification status
      if (status == STATUS_APPROVED) {
        await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
          'isVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error processing verification request: $e');
      rethrow;
    }
  }
  
  // Get verification request for current user
  Future<Map<String, dynamic>?> getCurrentUserVerificationRequest() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      return await checkVerificationStatus(user.uid);
    } catch (e) {
      print('Error getting current user verification request: $e');
      rethrow;
    }
  }
  
  // Check if user can submit a new verification request
  Future<bool> canSubmitVerificationRequest() async {
    try {
      final status = await getCurrentUserVerificationRequest();
      
      // If no previous requests, or last request was rejected, user can submit
      if (status == null || !status['hasSubmitted']) {
        return true;
      }
      
      // If last request is still pending, user cannot submit
      if (status['status'] == STATUS_PENDING) {
        return false;
      }
      
      // If last request was rejected, check if cooling period has passed (30 days)
      if (status['status'] == STATUS_REJECTED) {
        final reviewedAt = status['reviewedAt'] as Timestamp?;
        if (reviewedAt != null) {
          final cooldownEnds = reviewedAt.toDate().add(Duration(days: 30));
          return DateTime.now().isAfter(cooldownEnds);
        }
      }
      
      // If already approved, no need for another request
      if (status['status'] == STATUS_APPROVED) {
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking if can submit verification request: $e');
      return false;
    }
  }
  
  // Check if user is an admin
  Future<bool> isUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      final adminDoc = await _firestore
          .collection(_adminCollection)
          .doc(user.uid)
          .get();
          
      return adminDoc.exists;
    } catch (e) {
      print('Error checking if user is admin: $e');
      return false;
    }
  }
  
  // Get count of verification requests by status
  Future<Map<String, int>> getVerificationRequestCounts() async {
    try {
      final counts = <String, int>{
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
      
      final querySnapshot = await _firestore
          .collection(_verificationCollection)
          .get();
          
      counts['total'] = querySnapshot.size;
      
      for (final doc in querySnapshot.docs) {
        final status = doc.data()['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      print('Error getting verification request counts: $e');
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
    }
  }
}