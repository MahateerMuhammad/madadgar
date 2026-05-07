import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:***REMOVED***/models/verification_request.dart';
import 'package:path/path.dart' as path;

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionName = 'verifications';

  /// Submits a new verification request
  Future<void> submitVerificationRequest({
    required VerificationRequestModel request,
    required File cnicImageFile,
    required File faceImageFile,
  }) async {
    try {
      // 1. Upload Images to Storage
      String cnicUrl = await _uploadImage(
        file: cnicImageFile,
        userId: request.userId,
        type: 'cnic',
      );
      
      String faceUrl = await _uploadImage(
        file: faceImageFile,
        userId: request.userId,
        type: 'face',
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
      print('Verification request submitted successfully');
    } catch (e) {
      print('Error submitting verification request: $e');
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