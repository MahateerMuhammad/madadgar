import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'posts';

  // Add a new post to Firestore
  Future<void> addPost(PostModel post) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();
      final newPost = post.copyWith(id: docRef.id);
      await docRef.set(newPost.toMap());
      print('Post added successfully');
    } catch (e) {
      print("Error adding post: $e");
      rethrow;
    }
  }

  // Get all posts with optional filters
  Future<List<PostModel>> getPosts({
    PostType? type,
    String? category,
    PostStatus? status,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName).orderBy('createdAt', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      print("Fetched ${snapshot.docs.length} posts.");
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching posts: $e");
      rethrow;
    }
  }

  // Get posts by region with optional filters
  Future<List<PostModel>> getPostsByRegion({
    required String region,
    PostType? type,
    String? category,
    PostStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('region', isEqualTo: region)
          .orderBy('createdAt', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      print("Fetched ${snapshot.docs.length} posts for region: $region.");
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching posts by region: $e");
      rethrow;
    }
  }

  // Get current user's posts
  Future<List<PostModel>> getUserPosts({PostStatus? status}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      print("Fetched ${snapshot.docs.length} posts for user: $userId.");
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching user posts: $e");
      rethrow;
    }
  }

  // Delete a post by ID
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).delete();
      print("Post with ID: $postId deleted successfully.");
    } catch (e) {
      print("Error deleting post: $e");
      rethrow;
    }
  }
}
