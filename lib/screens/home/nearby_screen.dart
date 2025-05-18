// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/screens/post/post_detail_screen.dart';
import 'package:madadgar/config/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/models/user.dart';
import 'package:madadgar/services/user_service.dart';
import 'package:madadgar/widgets/report_dialog.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  _NearbyScreenState createState() => _NearbyScreenState();
}
class _NearbyScreenState extends State<NearbyScreen>
    with TickerProviderStateMixin {
  List<PostModel> _nearbyPosts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Add a map to store user verification data
  Map<String, bool> _userVerificationMap = {};
  Map<String, UserModel> _userDataMap = {};
  
  // Add scroll controller
  final ScrollController _scrollController = ScrollController();

  // Animation controllers for item animations
  final List<AnimationController> _itemAnimationControllers = [];
  final List<Animation<double>> _itemAnimations = [];

  @override
  void initState() {
    super.initState();
    _loadNearbyPosts();
    
    // Use a proper delay for post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose all item animation controllers
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use a proper delay to avoid layout issues during transitions
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() {});
    });
  }

  void _showReportDialog(PostModel post) {
  showDialog(
    context: context,
    builder: (context) => ReportDialog(
      postId: post.id,
      reportedUserId: post.userId,
      onReportSubmitted: () {
        // Optional: Refresh posts after report is submitted
        _loadNearbyPosts();
      },
    ),
  );
}

 void _showPostOptions(PostModel post) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Report option
          ListTile(
            leading: Icon(
              Icons.flag_outlined,
              color: Colors.red[600],
            ),
            title: Text(
              'Report Post',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showReportDialog(post);
            },
          ),
          
          // Cancel option
          ListTile(
            leading: Icon(
              Icons.close_rounded,
              color: Colors.grey[600],
            ),
            title: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
                color: Colors.grey[600],
              ),
            ),
            onTap: () => Navigator.pop(context),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}


  // Initialize animations for list items
  void _initItemAnimations(int itemCount) {
    // Clear any existing controllers
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    _itemAnimationControllers.clear();
    _itemAnimations.clear();

    // Create new controllers and animations
    for (int i = 0; i < itemCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400),
      );

      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutQuart,
      );

      _itemAnimationControllers.add(controller);
      _itemAnimations.add(animation);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: 50 * i), () {
        controller.forward();
      });
    }
  }

  // Modified method to prefetch user data
 Future<void> _loadNearbyPosts() async {
  try {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final postService = Provider.of<PostService>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';

    final user = authService.currentUser;
    if (user == null || user.region.isEmpty) {
      throw Exception('User region not found.');
    }

    // Get posts by region AND only with active status
    final posts = await postService.getPostsByRegion(
      region: user.region,
      status: PostStatus.active, // Only show active posts
    );
    
    // Filter out posts created by the current user
    final filteredPosts = posts.where((post) => post.userId != currentUserId).toList();
    
    // Clear previous user data cache
    _userVerificationMap.clear();
    _userDataMap.clear();
    
    // Prefetch user data for all posts
    for (var post in filteredPosts) {
      if (!_userVerificationMap.containsKey(post.userId)) {
        try {
          final userData = await UserService().getUserById(post.userId);
          _userVerificationMap[post.userId] = userData.isVerified;
          _userDataMap[post.userId] = userData;
        } catch (e) {
          print('Error fetching user data for ${post.userId}: $e');
          _userVerificationMap[post.userId] = false;
        }
      }
    }

    setState(() {
      _nearbyPosts = filteredPosts;
      _isLoading = false;

      // Initialize animations when posts are loaded
      if (filteredPosts.isNotEmpty) {
        _initItemAnimations(filteredPosts.length);
      }
    });
  } catch (e) {
    print("Error loading nearby posts: $e");
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Unable to load nearby posts. Please try again.';
    });
  }
}

  String _formatPostDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${dateTime.day} ${_getMonth(dateTime.month)} ${dateTime.year}';
    } else if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        onRefresh: _loadNearbyPosts,
        child: _isLoading
            ? _buildLoadingState(primaryColor, fontFamily)
            : _hasError
                ? _buildErrorState(fontFamily, primaryColor)
                : _nearbyPosts.isEmpty
                    ? _buildEmptyState(fontFamily, primaryColor)
                    : _buildPostsList(_nearbyPosts, fontFamily, primaryColor),
      ),
    );
  }

  Widget _buildLoadingState(Color primaryColor, String fontFamily) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading nearby posts...',
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String fontFamily, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load nearby posts',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loadNearbyPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Try Again',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String fontFamily, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_state.png',
            height: 120,
            width: 120,
            errorBuilder: (context, error, _) => Icon(
              Icons.location_off_rounded,
              size: 80,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No nearby posts found',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: Text(
              'Be the first to post help offers or requests in your area!',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/create-post');
            },
            icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor),
            label: Text(
              'Create Post',
              style: TextStyle(
                fontFamily: fontFamily,
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Improved post list builder to prevent overflow issues
  Widget _buildPostsList(List<PostModel> posts, String fontFamily, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView.builder(
        key: ValueKey('nearby_post_list_${DateTime.now().millisecondsSinceEpoch}'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 500,
        shrinkWrap: false,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          
          return FadeTransition(
            opacity: _itemAnimations.isNotEmpty
                ? _itemAnimations[index]
                : const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: _itemAnimations.isNotEmpty
                  ? Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(_itemAnimations[index])
                  : const AlwaysStoppedAnimation(Offset.zero),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildPostCard(post, index, fontFamily, primaryColor, constraints);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Modified post card builder that uses cached user data
  Widget _buildPostCard(
    PostModel post, int index, String fontFamily, Color primaryColor, BoxConstraints constraints) {
    
    // Get user verification status from cache
    final isUserVerified = _userVerificationMap[post.userId] ?? false;
    
    // Get user data from cache for help and thank counts
    final userData = _userDataMap[post.userId];
    final helpCount = userData?.helpCount ?? 0;
    final thankCount = userData?.thankCount ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Hero(
        tag: 'post_${post.id}',
        // Use a placeholder on Hero flight
        flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          elevation: 0,
          child: InkWell(
            onTap: () async {
              final currentUser = FirebaseAuth.instance.currentUser;

              // Only increment if viewer is not the post creator
              if (currentUser != null && currentUser.uid != post.userId) {
                await PostService().incrementViewCount(post.id);
              }

              // Navigate and wait for return
              await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PostDetailScreen(post: post),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );

              // Update state after navigation with proper delay
              if (mounted) {
                // Add a short delay to ensure proper frame scheduling
                await Future.delayed(const Duration(milliseconds: 100));
                _loadNearbyPosts(); // Reload posts after coming back
              }
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: primaryColor.withOpacity(0.05),
            highlightColor: primaryColor.withOpacity(0.05),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 0,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content section (removed image section)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                             Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatPostDate(post.createdAt),
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Three-dot menu button
                                  InkWell(
                                    onTap: () => _showPostOptions(post),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.more_vert_rounded,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // User info row - with cached verification status
                              _buildUserInfoRow(post, helpCount, thankCount, fontFamily, primaryColor, isUserVerified),
                              
                              const SizedBox(height: 12),
                              
                              // Post badges (type & category)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildPostTypeBadge(post.type, fontFamily, primaryColor),
                                  _buildCategoryBadge(post.category, fontFamily, primaryColor),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Post title with limited lines
                              Text(
                                post.title,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black.withOpacity(0.85),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              
                              // Post description with limited lines
                              Text(
                                post.description,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 13,
                                  color: Colors.black.withOpacity(0.65),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Footer row
                              _buildFooterRow(post, fontFamily, primaryColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // User info row with direct verification status parameter
 Widget _buildUserInfoRow(PostModel post, int helpCount, int thankCount, String fontFamily, Color primaryColor, bool isUserVerified) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // User avatar
      Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: primaryColor.withOpacity(0.1),
          backgroundImage: post.userImage.isNotEmpty
            ? NetworkImage(post.userImage)
            : null,
          child: post.userImage.isEmpty
            ? Text(
                post.userName.isNotEmpty 
                  ? post.userName[0].toUpperCase()
                  : '?',
                style: TextStyle(
                  fontFamily: fontFamily,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              )
            : null,
        ),
      ),
      const SizedBox(width: 10),
      
      // Username, verification badge, and location
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    post.userName,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Show appropriate verification status
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: isUserVerified
                    ? const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Color(0xFF1DA1F2),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Not Verified',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    post.region,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      
      // User stats
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatBadge(Icons.handshake_outlined, helpCount, fontFamily),
          const SizedBox(width: 4),
          _buildStatBadge(Icons.favorite_border_rounded, thankCount, fontFamily),
          
          // ADD THIS: Options button for post menu
          const SizedBox(width: 8),
        
        ],
      ),
    ],
  );
}

  // Other methods remain unchanged
  Widget _buildPostImage(PostModel post, String fontFamily, Color primaryColor) {
    // Implementation remains unchanged
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: post.images.isNotEmpty
              ? Image.network(
                  post.images.first,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: primaryColor.withOpacity(0.3),
                      size: 40,
                    ),
                  ),
                )
              : Container(color: Colors.grey[200]),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatPostDate(post.createdAt),
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterRow(PostModel post, String fontFamily, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // View count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_rounded,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 3),
            Text(
              '${post.viewCount} ${post.viewCount == 1 ? 'view' : 'views'}',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        // Tap to engage hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 12,
                color: primaryColor,
              ),
              const SizedBox(width: 3),
              Text(
                'Tap to engage',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 11,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, int count, String fontFamily) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeBadge(
      PostType type, String fontFamily, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: type == PostType.offer
            ? const Color(0xFF2E7D32).withOpacity(0.9)
            : const Color(0xFF1565C0).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (type == PostType.offer
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1565C0))
                .withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == PostType.offer
                ? Icons.volunteer_activism_rounded
                : Icons.help_outline_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            type.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(
      String category, String fontFamily, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontFamily: fontFamily,
          color: primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}