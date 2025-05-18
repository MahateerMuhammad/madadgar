import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/models/user.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/models/education.dart';
import 'package:madadgar/services/user_service.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/services/edu_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madadgar/screens/education/resource_detail_screen.dart';
import 'package:madadgar/screens/post/post_detail_screen.dart';
import 'package:madadgar/screens/profile/user_report_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  final EducationalResourceService _educationalResourceService = EducationalResourceService();
  
  late Future<UserModel> _userFuture;
  TabController? _tabController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<List<EducationalResourceModel>> _fetchUserResources() async {
    try {
      return await _educationalResourceService.getResourcesByUploader(widget.userId);
    } catch (e) {
      print('Error fetching user resources: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;
    
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
                      Tab(
                        icon: Icon(Icons.school),
                        text: 'Resources',
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
                      
                      // Educational Resources Tab
                      _buildResourcesTab(fontFamily),
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
    final primaryColor = MadadgarTheme.primaryColor;
    
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
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;
    
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

  Widget _buildResourcesTab(String fontFamily) {
    return FutureBuilder<List<EducationalResourceModel>>(
      future: _fetchUserResources(),
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
        
        final resources = snapshot.data ?? [];
        if (resources.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No educational resources yet',
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
          itemCount: resources.length,
          itemBuilder: (context, index) {
            return _buildResourceCard(resources[index], fontFamily);
          },
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post, String fontFamily) {
    final primaryColor = MadadgarTheme.primaryColor;
    
    return InkWell(
      onTap: () {
        // Navigate to post detail only if the post is active
        if (post.status == PostStatus.active) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: post.type == PostType.need 
                          ? Colors.orange.withOpacity(0.1) 
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      post.type == PostType.need 
                          ? Icons.help_outline 
                          : Icons.volunteer_activism,
                      color: post.type == PostType.need 
                          ? Colors.orange[700] 
                          : Colors.green[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(post.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _formatStatus(post.status),
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 12,
                        color: _getStatusColor(post.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.description,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      post.category,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${post.viewCount} views",
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(EducationalResourceModel resource, String fontFamily) {
    return InkWell(
      onTap: () {
        // Navigate to resource detail screen when clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(resource: resource),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResourceTypeIcon(resource.fileType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.description,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            resource.category,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                        if (resource.subCategory.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              resource.subCategory,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "${resource.likeCount}",
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(Icons.download, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "${resource.downloadCount}",
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(resource.createdAt),
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceTypeIcon(String fileType) {
    IconData icon;
    Color color;
    
    switch (fileType.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        color = Colors.orange;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        icon = Icons.image;
        color = Colors.purple;
        break;
      case 'video':
      case 'mp4':
        icon = Icons.video_library;
        color = Colors.red.shade700;
        break;
      case 'audio':
      case 'mp3':
        icon = Icons.audiotrack;
        color = Colors.cyan;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
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