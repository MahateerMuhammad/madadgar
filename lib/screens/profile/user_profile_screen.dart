//ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously,deprecated_member_use, prefer_const_literals_to_create_immutables, unnecessary_null_comparison, avoid_unnecessary_containers, prefer_interpolation_to_compose_strings, unused_local_variable, prefer_final_fields, prefer_typing_uninitialized_variables, avoid_print, unnecessary_new, prefer_const_constructors_in_immutables

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:***REMOVED***/config/theme.dart';
import 'package:***REMOVED***/models/user.dart';
import 'package:***REMOVED***/models/post.dart';
import 'package:***REMOVED***/services/user_service.dart';
import 'package:***REMOVED***/services/post_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:***REMOVED***/screens/post/post_detail_screen.dart';
import 'package:***REMOVED***/screens/profile/user_report_screen.dart';
import 'package:***REMOVED***/screens/verification/cnic_scan_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  
  late Future<UserModel> _userFuture;
  TabController? _tabController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _tabController = TabController(length: 1, vsync: this);
    _tabController!.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _loadUserData() {
    _userFuture = _userService.getUserById(widget.userId);
  }

  Future<List<PostModel>> _fetchUserPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PostModel.fromMap(data).copyWith(id: doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching user posts: $e');
      rethrow;
    }
  }



  @override
  Widget build(BuildContext context) {
    final fontFamily = MadadgarTheme.fontFamily;
    const primaryColor = MadadgarTheme.primaryColor;
    
    if (_tabController == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "User Profile",
          style: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            color: MadadgarTheme.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MadadgarTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          )
        : FutureBuilder<UserModel>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    color: Colors.red,
                  ),
                ),
              );
            }
            
            if (!snapshot.hasData) {
              return Center(
                child: Text(
                  'User not found',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16,
                  ),
                ),
              );
            }
            
            final user = snapshot.data!;
            
            return Column(
              children: [
                _buildUserProfileHeader(user),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryColor,
                    labelStyle: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.post_add),
                        text: 'Posts',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Posts Tab
                      _buildPostsTab(fontFamily),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
    );
  }

  Widget _buildUserProfileHeader(UserModel user) {
    final fontFamily = MadadgarTheme.fontFamily;
    const primaryColor = MadadgarTheme.primaryColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          // Profile image
          user.profileImage.isNotEmpty
              ? CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user.profileImage),
                )
              : CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 40,
                      color: primaryColor,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          
          // User name and verification badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 20,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Location/Region
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                user.region.isNotEmpty ? user.region : "Unknown location",
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem("Helped", user.helpCount.toString(), Icons.volunteer_activism),
              const SizedBox(width: 40),
              _buildStatItem("Thanks", user.thankCount.toString(), Icons.favorite),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Member since
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Member since: ${_formatDate(user.createdAt)}',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add report button
            if (user.id != FirebaseAuth.instance.currentUser?.uid)
              OutlinedButton.icon(
                onPressed: () => _openReportUserDialog(user),
                icon: Icon(Icons.flag, size: 18,color:Colors.red[700] ,),
                label: Text(
                  'Report',
                  style: TextStyle(fontFamily: fontFamily),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            
            // Add Verify Identity button
            if (user.id == FirebaseAuth.instance.currentUser?.uid && !user.isVerified)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CnicScanScreen()),
                  );
                },
                icon: const Icon(Icons.security, size: 18, color: Colors.white),
                label: Text(
                  'Verify Identity',
                  style: TextStyle(fontFamily: fontFamily, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MadadgarTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final fontFamily = MadadgarTheme.fontFamily;
    const primaryColor = MadadgarTheme.primaryColor;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(String fontFamily) {
    return FutureBuilder<List<PostModel>>(
      future: _fetchUserPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(fontFamily: fontFamily),
            ),
          );
        }
        
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.post_add,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(posts[index], fontFamily);
          },
        );
      },
    );
  }



  Color _getStatusColor(PostStatus status) {
    switch (status) {
      case PostStatus.active:
        return Colors.green;
      case PostStatus.fulfilled:
        return Colors.blue;
      case PostStatus.closed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  // Add this method to your _UserProfileScreenState class
void _openReportUserDialog(UserModel user) {
  final fontFamily = MadadgarTheme.fontFamily;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Report User',
        style: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to report this user?',
        style: TextStyle(fontFamily: fontFamily),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.grey[700],
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MadadgarTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
            // Navigate to report screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportUserScreen(
                  reportedUserId: widget.userId,
                  reportedUserName: user.name, // Replace with actual user name
                ),
              ),
            );
          },
          child: Text(
            'Report',
            style: TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

  String _formatStatus(PostStatus status) {
    switch (status) {
      case PostStatus.active:
        return 'Active';
      case PostStatus.fulfilled:
        return 'Fulfilled';
      case PostStatus.closed:
        return 'Closed';
      default:
        return 'Unknown';
    }
  }
}