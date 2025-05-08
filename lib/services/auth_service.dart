import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madadgar/config/constants.dart';
import 'package:madadgar/models/user.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  
  // Constructor sets up auth state listener
  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  // Auth state change handler
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();
          
      if (userDoc.exists) {
        _currentUser = UserModel.fromMap(userDoc.data()!);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error fetching user data: $e');
      _currentUser = null;
      notifyListeners();
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }
  
  // Register user
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String region,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user!;
      
      // Create user in Firestore
      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        phone: phone,
        region: region,
        isVerified: false,
        createdAt: now,
        updatedAt: now,
      );
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());
      
      // Send email verification
      await user.sendEmailVerification();
      
      return userModel;
    } catch (e) {
      rethrow;
    }
  }
  
  // Login user
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
       await Future.delayed(const Duration(seconds: 1));
      // _onAuthStateChanged will handle loading the user
      if (_currentUser == null) {
        throw Exception('Failed to load user data');
      }
      
      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }
  
  // Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? region,
    String? profileImage,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('User not logged in');
      }
      
      final updatedUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        region: region,
        profileImage: profileImage,
      );
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.id)
          .update(updatedUser.toMap());
      
      _currentUser = updatedUser;
      notifyListeners();
      
      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      // Verify current password is correct
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user stats
  Future<void> updateStats({bool increaseHelp = false, bool increaseThanks = false}) async {
    if (_currentUser == null) return;
    
    try {
      final updates = <String, dynamic>{};
      
      if (increaseHelp) {
        updates['helpCount'] = FieldValue.increment(1);
      }
      
      if (increaseThanks) {
        updates['thankCount'] = FieldValue.increment(1);
      }
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(_currentUser!.id)
            .update(updates);
            
        // Update local user copy
        if (increaseHelp) {
          _currentUser = _currentUser!.copyWith(
            helpCount: _currentUser!.helpCount + 1
          );
        }
        
        if (increaseThanks) {
          _currentUser = _currentUser!.copyWith(
            thankCount: _currentUser!.thankCount + 1
          );
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error updating stats: $e');
    }
  }
}