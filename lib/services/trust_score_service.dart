import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:***REMOVED***/models/user.dart';

class TrustScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  /// Calculates the trust score based on a user's activity.
  /// 
  /// Factors:
  /// - Base score for verified users: 20
  /// - Each help provided: +10 points
  /// - Each thank received: +5 points
  /// - Maximum score is capped at 100.
  int calculateTrustScore(UserModel user) {
    int score = 0;
    
    if (user.isVerified) {
      score += 20;
    }
    
    score += (user.helpCount * 10);
    score += (user.thankCount * 5);
    
    // Cap at 100
    return score > 100 ? 100 : score;
  }

  /// Updates the trust score in Firestore for a given user.
  Future<void> updateTrustScore(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection(_collectionName).doc(userId).get();
      if (userDoc.exists) {
        UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        
        int newScore = calculateTrustScore(user);
        
        if (newScore != user.trustScore) {
          await _firestore.collection(_collectionName).doc(userId).update({
            'trustScore': newScore,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Trust score updated for user $userId: $newScore');
        }
      }
    } catch (e) {
      print('Error updating trust score: $e');
      rethrow;
    }
  }

  /// Gets a badge tier based on the trust score.
  /// 
  /// Tiers:
  /// 0-30: Bronze
  /// 31-70: Silver
  /// 71-100: Gold
  String getTrustTier(int score) {
    if (score >= 71) return 'Gold';
    if (score >= 31) return 'Silver';
    return 'Bronze';
  }
}
