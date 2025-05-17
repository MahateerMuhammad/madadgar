// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madadgar/models/user.dart';
import 'package:madadgar/screens/auth/login_screen.dart';
import 'package:madadgar/services/user_service.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/screens/post/my_posts_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/screens/profile/settings_screen.dart';
import 'package:madadgar/screens/verification/verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();

  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(builder: (_) => const ProfileScreen());
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isUpdatingImage = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _postsCount = 0;
  
  // Animation controllers
  final double _cardElevation = 4.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get current user data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle not logged in
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }

      // Load user model from Firestore
      final userData = await _userService.getUserById(user.uid);
      
      // Fetch post count for the current user
      final userPosts = await _postService.getUserPosts();
      final postCount = userPosts.length;

      if (mounted) {
        setState(() {
          _userModel = userData;
          _postsCount = postCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error loading profile data. Please try again.';
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password reset email sent.")));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _refreshAuthServiceUser(BuildContext context) {
    // Call the static method in AuthService to refresh the current user
    AuthService.refreshAuthServiceUser(context);
  }

  Future<void> _updateProfilePicture() async {
    if (_isUpdatingImage) return;

    try {
      setState(() => _isUpdatingImage = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) {
        setState(() => _isUpdatingImage = false);
        return;
      }

      final file = File(image.path);

      // Store the current profile image URL to delete it later
      final String? currentProfileImageUrl = _userModel?.profileImage;

      // Prepare Cloudinary upload URL
      final String cloudName = "ddppfyrcv"; 
      final String presetName = "madadgar"; 
      final String uploadUrl = "https://api.cloudinary.com/v1_1/ddppfyrcv/image/upload";

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['upload_preset'] = presetName;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final Map<String, dynamic> responseMap = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        final downloadUrl = responseMap['secure_url'];

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Update user profile in Firebase Auth
          await user.updatePhotoURL(downloadUrl);

          // Update user model in Firestore
          await _userService.updateUser(user.uid, {
            'profileImage': downloadUrl,
            'updatedAt': DateTime.now().toIso8601String()
          });

          await PostService().updateUserImageInPosts(user.uid, downloadUrl);

          // Delete previous profile image from Cloudinary if it exists
          if (currentProfileImageUrl != null &&
              currentProfileImageUrl.isNotEmpty) {
            await _deleteCloudinaryImage(currentProfileImageUrl);
          }

          // Reload user data
          await _loadUserData();

          // Refresh the AuthService to update drawer
          _refreshAuthServiceUser(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Profile picture updated successfully")),
          );
        }
      } else {
        throw Exception("Failed to upload image to Cloudinary");
      }
    } catch (e) {
      print("Error updating profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile picture: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingImage = false);
      }
    }
  }

  Future<void> _deleteCloudinaryImage(String imageUrl) async {
    try {
      // Extract public ID from Cloudinary URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 4) {
        print("Invalid Cloudinary URL format");
        return;
      }

      // Get the public ID with version and extension
      String fullPublicId = pathSegments.sublist(2).join('/');

      // Remove version and extension to get clean public ID
      final versionMatch = RegExp(r'v\d+/(.+)').firstMatch(fullPublicId);
      if (versionMatch != null && versionMatch.groupCount >= 1) {
        fullPublicId = versionMatch.group(1)!;
      }

      // Remove extension if present
      final lastDotIndex = fullPublicId.lastIndexOf('.');
      if (lastDotIndex != -1) {
        fullPublicId = fullPublicId.substring(0, lastDotIndex);
      }

      print("Would delete Cloudinary image with public ID: $fullPublicId");
    } catch (e) {
      print("Error while trying to delete Cloudinary image: $e");
    }
  }

  void _navigateToMyPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyPostsScreen()),
    ).then((_) => _loadUserData());
  }

  void _openSettings() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}
  
  void _editProfile() {
    // Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit profile coming soon")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadUserData,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadUserData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Try Again',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Modern app bar with slight blur effect
                      SliverAppBar(
                        expandedHeight: 0,
                        backgroundColor: Colors.white,
                        elevation: 0,
                        pinned: true,
                        actions: [
                          IconButton(
                            icon: Icon(Icons.settings_outlined, color: primaryColor),
                            onPressed: _openSettings,
                          ),
                          IconButton(
                            icon: Icon(Icons.logout, color: Colors.red.shade400),
                            onPressed: _logout,
                          ),
                        ],
                      ),
                      
                      // Profile Header
                      SliverToBoxAdapter(
                        child: _buildProfileHeader(screenWidth, primaryColor, fontFamily),
                      ),
                      
                      // Stats Card
                      SliverToBoxAdapter(
                        child: _buildStatsCard(fontFamily, primaryColor),
                      ),
                    ],
                  ),
      ),
    );
  }
  
  Widget _buildProfileHeader(double screenWidth, Color primaryColor, String fontFamily) {
    final user = FirebaseAuth.instance.currentUser;
    String? photoUrl = _userModel?.profileImage;
    
    // If user model doesn't have image but Firebase Auth does
    if ((photoUrl == null || photoUrl.isEmpty) && user?.photoURL != null) {
      photoUrl = user!.photoURL;
    }
    
    final displayName = _userModel?.name ?? user?.displayName ?? "User";
    final email = _userModel?.email ?? user?.email ?? "";
    final region = _userModel?.region ?? "";
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Profile Image with Animation
          Hero(
            tag: 'profileImage',
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Material(
                    elevation: 0,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                        image: photoUrl != null && photoUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? const Icon(Icons.person, size: 70, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _updateProfilePicture,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: _isUpdatingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          
          // User Name
          Text(
            displayName,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 5),
          
          // Email
          Text(
            email,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          
          if (region.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  region,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 15),
          
          // Bio (Placeholder, you can add a real bio from user model)
        
          
          const SizedBox(height: 20),
          
          // Edit Profile Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: _editProfile,
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
                backgroundColor: primaryColor.withOpacity(0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to My Posts
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>VerificationScreen()),
                ).then((_) => _loadUserData());
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
                backgroundColor: primaryColor.withOpacity(0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: Text(
                'Verify Yourself',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Verification Badge
          if (_userModel?.isVerified == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    "Verified Account",
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String fontFamily, Color primaryColor) {
    final helpCount = _userModel?.helpCount ?? 0;
    final thankCount = _userModel?.thankCount ?? 0;
    // Using actual posts count from database
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Posts Count - Now using the actual count from database
          _buildAnimatedStatItem(
            "Posts",
            _postsCount.toString(),
            Icons.article_outlined,
            primaryColor,
            fontFamily,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          // Helped Count
          _buildAnimatedStatItem(
            "Helped",
            helpCount.toString(),
            Icons.handshake_outlined,
            primaryColor,
            fontFamily,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          // Thanks Count
          _buildAnimatedStatItem(
            "Thanks",
            thankCount.toString(),
            Icons.favorite_outline,
            Colors.redAccent,
            fontFamily,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedStatItem(
      String label, String value, IconData icon, Color color, String fontFamily) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, (1 - val) * 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}