import 'package:cloud_firestore/cloud_firestore.dart';

class WaitlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'waitlist';

  /// Adds a user to the pre-launch waitlist.
  Future<void> joinWaitlist(String email, String region, {String? name}) async {
    try {
      // Check if email already exists
      QuerySnapshot existing = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .get();
          
      if (existing.docs.isNotEmpty) {
        throw Exception('Email is already on the waitlist.');
      }

      await _firestore.collection(_collectionName).add({
        'email': email,
        'region': region,
        'name': name ?? '',
        'status': 'pending', // pending, invited, active
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      print('User added to waitlist successfully.');
    } catch (e) {
      print('Error joining waitlist: $e');
      rethrow;
    }
  }

  /// Invites a user from the waitlist (Admin only).
  Future<void> inviteUser(String waitlistId) async {
    try {
      await _firestore.collection(_collectionName).doc(waitlistId).update({
        'status': 'invited',
        'invitedAt': FieldValue.serverTimestamp(),
      });
      print('User invited successfully.');
    } catch (e) {
      print('Error inviting user: $e');
      rethrow;
    }
  }
}
