import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:***REMOVED***/models/post.dart';
import 'package:***REMOVED***/models/user.dart';

class SeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Flags a user as a partner organization.
  Future<void> flagAsPartnerOrg(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isPartnerOrg': true,
        'isVerified': true, // Partner orgs are automatically verified
        'trustScore': 100, // Max trust score
      });
      print('User $userId flagged as partner organization');
    } catch (e) {
      print('Error flagging partner org: $e');
      rethrow;
    }
  }

  /// Seeds initial posts on behalf of a partner organization.
  Future<void> seedInitialPosts(List<PostModel> initialPosts) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var post in initialPosts) {
        DocumentReference docRef = _firestore.collection('posts').doc();
        PostModel newPost = post.copyWith(id: docRef.id);
        batch.set(docRef, newPost.toMap());
      }
      
      await batch.commit();
      print('Successfully seeded ${initialPosts.length} posts');
    } catch (e) {
      print('Error seeding posts: $e');
      rethrow;
    }
  }
}
