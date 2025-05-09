import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  // Get user by ID
  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(userId).get();
      
      if (!doc.exists) {
        // If user doesn't exist in Firestore, create a new entry
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser == null) {
          throw Exception('User not authenticated');
        }
        
        // Create a new user model with data from Firebase Auth
        final newUser = UserModel(
          id: authUser.uid,
          name: authUser.displayName ?? 'User',
          email: authUser.email ?? '',
          phone: '',
          region: '',
          profileImage: authUser.photoURL ?? '',
          helpCount: 0,
          thankCount: 0,
          isVerified: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Save to Firestore
        await _firestore.collection(_collectionName).doc(authUser.uid).set(newUser.toMap());
        
        return newUser;
      }
      
      // Map document data to UserModel
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Ensure id field exists
      data['id'] = doc.id;
      
      return UserModel.fromMap(data);
    } catch (e) {
      print("Error getting user: $e");
      rethrow;
    }
  }

  // Update user fields
  Future<void> updateUser(String userId, Map<String, dynamic> fields) async {
    try {
      // Add updated timestamp
      fields['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore.collection(_collectionName).doc(userId).update(fields);
    } catch (e) {
      // If document doesn't exist, create it
      if (e is FirebaseException && e.code == 'not-found') {
        // Set default values for required fields
        if (!fields.containsKey('helpCount')) fields['helpCount'] = 0;
        if (!fields.containsKey('thankCount')) fields['thankCount'] = 0;
        if (!fields.containsKey('isVerified')) fields['isVerified'] = false;
        
        fields['createdAt'] = DateTime.now().toIso8601String();
        fields['updatedAt'] = DateTime.now().toIso8601String();
        
        await _firestore.collection(_collectionName).doc(userId).set(fields);
      } else {
        print("Error updating user: $e");
        rethrow;
      }
    }
  }
  
  // Update user using UserModel
  Future<void> updateUserWithModel(UserModel user) async {
    try {
      await _firestore.collection(_collectionName).doc(user.id).set(user.toMap());
    } catch (e) {
      print("Error updating user with model: $e");
      rethrow;
    }
  }

  // Update user profile image
  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'profileImage': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error updating profile image: $e");
      rethrow;
    }
  }

  // Increment help count
  Future<void> incrementHelpCount(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'helpCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error incrementing help count: $e");
      rethrow;
    }
  }
  
  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      Map<String, dynamic> data = doc.data();
      data['id'] = doc.id;
      
      return UserModel.fromMap(data);
    } catch (e) {
      print("Error getting user by email: $e");
      rethrow;
    }
  }
  
  // Increment thank count
  Future<void> incrementThankCount(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'thankCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error incrementing thank count: $e");
      rethrow;
    }
  }
  
  // Update user verification status
  Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'isVerified': isVerified,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error updating verification status: $e");
      rethrow;
    }
  }
  
  // Delete user account
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection(_collectionName).doc(userId).delete();
      
      // Delete user from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
      }
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }
  
  // Get top helpers (users with highest help count)
  Future<List<UserModel>> getTopHelpers({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('helpCount', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting top helpers: $e");
      rethrow;
    }
  }

  
  
  // Get most thanked users (users with highest thank count)
  Future<List<UserModel>> getMostThankedUsers({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('thankCount', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting most thanked users: $e");
      rethrow;
    }
  }
  
  // Get verified users only
  Future<List<UserModel>> getVerifiedUsers({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isVerified', isEqualTo: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting verified users: $e");
      rethrow;
    }
  }
  
  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(userId).get();
      return doc.exists;
    } catch (e) {
      print("Error checking if user exists: $e");
      rethrow;
    }
  }
  
  // Get users by region
  Future<List<UserModel>> getUsersByRegion(String region, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('region', isEqualTo: region)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting users by region: $e");
      rethrow;
    }
  }
  
  // Search users by name
  Future<List<UserModel>> searchUsersByName(String searchQuery, {int limit = 20}) async {
    try {
      // Get all users (this is not efficient for large datasets,
      // consider implementing a proper search index for production)
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .get();
      
      final searchTermLower = searchQuery.toLowerCase();
      
      // Filter users whose names contain the search term
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] as String).toLowerCase();
        return name.contains(searchTermLower);
      }).take(limit).toList();
      
      return filteredDocs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error searching users by name: $e");
      rethrow;
    }
  }
}
