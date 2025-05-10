import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isUpdatingImage = false;
  bool _hasError = false;
  String _errorMessage = '';

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

      if (mounted) {
        setState(() {
          _userModel = userData;
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
      final String cloudName =
          "ddppfyrcv"; // Replace with your Cloudinary cloud name
      final String presetName =
          "madadgar"; // Replace with your Cloudinary preset name
      final String uploadUrl =
          "https://api.cloudinary.com/v1_1/ddppfyrcv/image/upload";

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
      // URL format: https://res.cloudinary.com/<cloud_name>/image/upload/v<version>/<public_id>.<extension>
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 4) {
        print("Invalid Cloudinary URL format");
        return;
      }

      // Get the public ID with version and extension
      String fullPublicId = pathSegments.sublist(2).join('/');

      // Remove version and extension to get clean public ID
      // Format typically: v1234567890/folder/image
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
    // Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings screen coming soon")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    final accentColor =
        HSLColor.fromColor(primaryColor).withLightness(0.85).toColor();

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
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                : SafeArea(
                    child: CustomScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // App Bar with modern, minimal background
                        SliverAppBar(
                          expandedHeight: 200,
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Clean, minimal background
                                Container(
                                  color: Colors.white,
                                ),
                                // Modern accent shape
                                Positioned(
                                  top: -50,
                                  right: -20,
                                  child: Container(
                                    height: 200,
                                    width: 200,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // Secondary accent shape
                                Positioned(
                                  bottom: -30,
                                  left: -30,
                                  child: Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                // Subtle top wave decoration
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: ClipPath(
                                    clipper: _WaveClipper(),
                                    child: Container(
                                      height: 90,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            primaryColor.withOpacity(0.4),
                                            primaryColor.withOpacity(0.2),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Profile image centered
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 40),
                                    _buildProfileImage(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // User Info
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildUserInfo(),
                              const SizedBox(height: 16),
                              _buildStatistics(),
                              const SizedBox(height: 24),
                              _buildActionCards(),
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final user = FirebaseAuth.instance.currentUser;
    String? photoUrl = _userModel?.profileImage;

    // If user model doesn't have image but Firebase Auth does
    if ((photoUrl == null || photoUrl.isEmpty) && user?.photoURL != null) {
      photoUrl = user!.photoURL;
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
        ),
        GestureDetector(
          onTap: _updateProfilePicture,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isUpdatingImage
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          MadadgarTheme.primaryColor),
                    ),
                  )
                : Icon(Icons.camera_alt,
                    size: 24, color: MadadgarTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    final fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _userModel?.name ?? user?.displayName ?? "User";
    final email = _userModel?.email ?? user?.email ?? "";
    final phone = _userModel?.phone ?? "";
    final region = _userModel?.region ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            displayName,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              phone,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
          if (region.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.black54),
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
          if (_userModel?.isVerified == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    "Verified Account",
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final helpCount = _userModel?.helpCount ?? 0;
    final thankCount = _userModel?.thankCount ?? 0;
    final fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
            color: HSLColor.fromColor(primaryColor)
                .withLightness(0.85)
                .toColor()
                .withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            "Helped",
            helpCount.toString(),
            Icons.handshake,
            primaryColor,
            fontFamily,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
          _buildStatItem(
            "Thanks",
            thankCount.toString(),
            Icons.favorite,
            Colors.redAccent,
            fontFamily,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color,
      String fontFamily) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    final fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;
    final accentColor =
        HSLColor.fromColor(primaryColor).withLightness(0.85).toColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionCard(
            "Change Password",
            Icons.lock_outline,
            _changePassword,
            primaryColor,
            accentColor,
            fontFamily,
          ),
          _buildActionCard(
            "Settings",
            Icons.settings,
            _openSettings,
            primaryColor,
            accentColor,
            fontFamily,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String label, IconData icon, VoidCallback onTap,
      Color primaryColor, Color accentColor, String fontFamily) {
    return Container(
      width: 150,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.list_alt),
            label: Text(
              'View All My Posts',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              shadowColor: primaryColor.withOpacity(0.3),
            ),
            onPressed: _navigateToMyPosts,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(
              'Logout',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              shadowColor: Colors.red.withOpacity(0.3),
            ),
            onPressed: _logout,
          ),
        ),
      ],
    );
  }
}

// Custom clipper for the wave effect
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);

    var firstControlPoint = Offset(size.width / 4, size.height - 30);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height - 10);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
