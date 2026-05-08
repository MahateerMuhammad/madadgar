import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:madadgar/models/verification_request.dart';
import 'package:path/path.dart' as path;

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionName = 'verifications';

  // Add the statuses expected by the screen
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_APPROVED = 'approved';
  static const String STATUS_REJECTED = 'rejected';

  Future<Map<String, dynamic>?> getCurrentUserVerificationRequest(String userId) async {
    final snapshot = await _firestore.collection(_collectionName).where('userId', isEqualTo: userId).orderBy('submittedAt', descending: true).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  Future<bool> canSubmitVerificationRequest(String userId) async {
    final request = await getCurrentUserVerificationRequest(userId);
    if (request == null) return true;
    return request['status'] == STATUS_REJECTED;
  }

  /// Submits a new verification request (modified to fit both signatures by overloading or adding a new method)
  Future<void> submitVerificationRequest({
    required String userId,
    required File idCardFront,
    required File idCardBack,
    required String cnic,
    required String additionalInfo,
  }) async {
    try {
      // 1. Upload Images to Storage
      String cnicUrl = await _uploadImage(
        file: idCardFront,
        userId: userId,
        type: 'cnic_front',
      );
      
      String faceUrl = await _uploadImage(
        file: idCardBack,
        userId: userId,
        type: 'cnic_back',
      );

      // 2. Add URLs to model
      final docRef = _firestore.collection(_collectionName).doc();
      VerificationRequestModel request = VerificationRequestModel(
        id: docRef.id,
        userId: userId,
        cnicNumber: cnic,
        cnicImageUrl: cnicUrl, // saving front here
        faceImageUrl: faceUrl, // saving back here
        status: VerificationStatus.pending,
        submittedAt: DateTime.now(),
      );

      // 3. Save to Firestore
      await docRef.set(request.toMap());
      print('Verification request submitted successfully');
    } catch (e) {
      print('Error submitting verification request: $e');
      rethrow;
    }
  }

  /// Submits a new verification request from the ML Kit Live Flow
  Future<void> submitLiveVerificationRequest({
    required VerificationRequestModel request,
    required File cnicImageFile,
    required File faceImageFile,
  }) async {
    try {
      // 1. Upload Images to Storage
      String cnicUrl = await _uploadImage(
        file: cnicImageFile,
        userId: request.userId,
        type: 'cnic_front',
      );
      
      String faceUrl = await _uploadImage(
        file: faceImageFile,
        userId: request.userId,
        type: 'live_face',
      );

      // 2. Add URLs to model
      final docRef = _firestore.collection(_collectionName).doc();
      VerificationRequestModel finalRequest = request.copyWith(
        id: docRef.id,
        cnicImageUrl: cnicUrl,
        faceImageUrl: faceUrl,
        status: VerificationStatus.pending,
        submittedAt: DateTime.now(),
      );

      // 3. Save to Firestore
      await docRef.set(finalRequest.toMap());
      print('Live Verification request submitted successfully');
    } catch (e) {
      print('Error submitting live verification request: $e');
      rethrow;
    }
  }

  Future<String> _uploadImage({
    required File file,
    required String userId,
    required String type,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    final ref = _storage.ref().child('verifications/$userId/$type/$fileName');
    
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
