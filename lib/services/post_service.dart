import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'posts';

// Add this method to your PostService class in post_service.dart

Future<void> updatePost(PostModel post) async {
  try {
    await _firestore.collection(_collectionName).doc(post.id).update(post.toMap());
    print('Post updated successfully: ${post.id}');
  } catch (e) {
    print("Error updating post: $e");
    rethrow;
  }
}

  Future<void> updateUserImageInPosts(String userId, String newImageUrl) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('posts')
      .where('userId', isEqualTo: userId)
      .get();

  final batch = FirebaseFirestore.instance.batch();

  for (final doc in querySnapshot.docs) {
    batch.update(doc.reference, {'userImage': newImageUrl});
  }

  await batch.commit();
  print("Updated userImage in ${querySnapshot.docs.length} posts.");
}


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

  Future<void> incrementViewCount(String postId) async {
  try {
    final postRef = _firestore.collection(_collectionName).doc(postId);
    await postRef.update({'viewCount': FieldValue.increment(1)});
  } catch (e) {
    print("Error incrementing view count: $e");
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
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return PostModel.fromMap(data).copyWith(id: doc.id);
    }).toList();
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
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return PostModel.fromMap(data).copyWith(id: doc.id);
    }).toList();
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
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return PostModel.fromMap(data).copyWith(id: doc.id);
    }).toList();
  } catch (e) {
    print("Error fetching user posts: $e");
    rethrow;
  }
}

Future<int> getViewCount(String postId) async {
  final doc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
  return doc.data()?['viewCount'] ?? 0;
}


Future<PostModel> fetchPostById(String postId) async {
  final doc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
  if (doc.exists) {
    return PostModel.fromFirestore(doc);
  } else {
    throw Exception('Post not found');
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
