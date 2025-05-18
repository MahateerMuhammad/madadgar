// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/config/constants.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/screens/post/post_detail_screen.dart';
import 'package:madadgar/models/user.dart';
import 'package:madadgar/services/user_service.dart';
import 'package:madadgar/widgets/report_dialog.dart';
import 'package:madadgar/services/report_service.dart';
import 'package:madadgar/widgets/user_search.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late Future<List<PostModel>> _postsFuture;
  String _selectedCategory = 'All';
  PostType? _selectedType;
  final ScrollController _scrollController = ScrollController();
  bool _isFilterExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _filterAnimation;
   final ReportService _reportService = ReportService();
   bool _isSearchActive = false;
  
  // Animation for list items
  final List<AnimationController> _itemAnimationControllers = [];
  final List<Animation<double>> _itemAnimations = [];
  
  // Add a map to store user verification status
  final Map<String, bool> _userVerificationStatus = {};

 @override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Use a proper delay to avoid layout issues during transitions
  Future.delayed(const Duration(milliseconds: 50), () {
    if (mounted) setState(() {});
  });
}

// Update your initState method
@override
void initState() {
  super.initState();
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  
  _filterAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  );
  
  _loadPosts();
  
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
    _scrollController.dispose();
    _animationController.dispose();
    
    // Dispose all item animation controllers
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    
    super.dispose();
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

  Future<void> _preloadUserVerificationStatus(List<PostModel> posts) async {
    final userService = UserService();
    final Set<String> uniqueUserIds = posts.map((post) => post.userId).toSet();
    
    // Create a list of futures for parallel execution
    final futures = uniqueUserIds.map((userId) async {
      try {
        final user = await userService.getUserById(userId);
        _userVerificationStatus[userId] = user.isVerified;
      } catch (e) {
        // Handle error - default to not verified
        _userVerificationStatus[userId] = false;
      }
    }).toList();
    
    // Wait for all futures to complete
    await Future.wait(futures);
  }


   void _loadPosts() {
    final postService = Provider.of<PostService>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    
    setState(() {
      // Fetch posts and then filter out current user's posts
      _postsFuture = postService.getPosts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        type: _selectedType,
        status: PostStatus.active,
      ).then((posts) async {
        // Filter out posts created by the current user
        final filteredPosts = posts.where((post) => post.userId != currentUserId).toList();
        
        // Fetch verification status for all users in one go
        await _preloadUserVerificationStatus(filteredPosts);
        
        return filteredPosts;
      });
    });
  }

 @override
Widget build(BuildContext context) {
  super.build(context);
  final primaryColor = MadadgarTheme.primaryColor;
  final fontFamily = MadadgarTheme.fontFamily;
  
  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(fontFamily),
                // Only show filters when not in search mode
                if (!_isSearchActive)
                  SizeTransition(
                    sizeFactor: _filterAnimation,
                    child: _buildExpandedFilters(fontFamily),
                  ),
                Expanded(
                  child: _isSearchActive 
                      ? const UserSearchWidget() // Show search widget when search is active
                      : RefreshIndicator(
                          color: primaryColor,
                          backgroundColor: Colors.white,
                          strokeWidth: 2.5,
                          onRefresh: () async {
                            _loadPosts();
                          },
                          child: FutureBuilder<List<PostModel>>(
                            future: _postsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildLoadingState(primaryColor);
                              }
                              
                              if (snapshot.hasError) {
                                return _buildErrorState(fontFamily, primaryColor);
                              }
                              
                              final posts = snapshot.data ?? [];
                              
                              if (posts.isEmpty) {
                                return _buildEmptyState(fontFamily, primaryColor);
                              }
                              
                              // Initialize animations when posts are loaded
                              _initItemAnimations(posts.length);
                              
                              return _buildPostsList(posts, fontFamily, primaryColor);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

 // Modify the _buildHeader method to include the search toggle button
Widget _buildHeader(String fontFamily) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          offset: const Offset(0, 2),
          blurRadius: 10,
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Only show type filters if not in search mode
            if (!_isSearchActive)
              Row(
                children: [
                  _buildTypeFilter(null, 'All', fontFamily),
                  const SizedBox(width: 8),
                  _buildTypeFilter(PostType.need, 'Needs', fontFamily),
                  const SizedBox(width: 8),
                  _buildTypeFilter(PostType.offer, 'Offers', fontFamily),
                ],
              )
            else
              Text(
                'User Search',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            Row(
              children: [
                // Search toggle button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchActive = !_isSearchActive;
                      // If closing search, ensure filters are closed too
                      if (!_isSearchActive && _isFilterExpanded) {
                        _isFilterExpanded = false;
                        _animationController.reverse();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isSearchActive ? MadadgarTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSearchActive ? MadadgarTheme.primaryColor.withOpacity(0.2) : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _isSearchActive ? Icons.close : Icons.search,
                      size: 20,
                      color: _isSearchActive ? MadadgarTheme.primaryColor : Colors.grey[700],
                    ),
                  ),
                ),
                // Only show filter button when not in search mode
                if (!_isSearchActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFilterExpanded = !_isFilterExpanded;
                          if (_isFilterExpanded) {
                            _animationController.forward();
                          } else {
                            _animationController.reverse();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isFilterExpanded ? MadadgarTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isFilterExpanded ? MadadgarTheme.primaryColor.withOpacity(0.2) : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _isFilterExpanded ? Icons.filter_list : Icons.filter_alt_outlined,
                          size: 20,
                          color: _isFilterExpanded ? MadadgarTheme.primaryColor : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
  Widget _buildTypeFilter(PostType? type, String label, String fontFamily) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = isSelected ? null : type;
          _loadPosts();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? MadadgarTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? MadadgarTheme.primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: fontFamily,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedFilters(String fontFamily) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 1,
            color: Colors.grey[200],
          ),
          Text(
            'Categories',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip('All', fontFamily),
              ...AppConstants.categories.map((category) => _buildCategoryChip(category, fontFamily)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                  _selectedType = null;
                  _isFilterExpanded = false;
                  _animationController.reverse();
                  _loadPosts();
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Reset Filters', 
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 13
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String fontFamily) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _loadPosts();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? MadadgarTheme.primaryColor.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? MadadgarTheme.primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontFamily: fontFamily,
            color: isSelected ? MadadgarTheme.primaryColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
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
            'Loading posts...',
            style: TextStyle(
              fontFamily: MadadgarTheme.fontFamily,
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
              'Unable to load feed',
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
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
              Icons.post_add_rounded,
              size: 80,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No posts found',
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
              _selectedCategory != 'All' || _selectedType != null
                  ? 'Try changing your filters or be the first to create a post in this category'
                  : 'Be the first to create a post and start helping the community',
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
        
        ],
      ),
    );
  }


Widget _buildPostsList(List<PostModel> posts, String fontFamily, Color primaryColor) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: ListView.builder(
      key: ValueKey('post_list_${DateTime.now().millisecondsSinceEpoch}'), // Use ValueKey instead of PageStorageKey
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 500,
      // Add this to avoid layout issues
      shrinkWrap: false,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        
        // Use a uniform height constraint for all post cards
        return FadeTransition(
          opacity: _itemAnimations[index],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(_itemAnimations[index]),
            // Wrap with a SizedBox with a minimum height constraint
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



  Widget _buildPostCard(PostModel post, int index, String fontFamily, Color primaryColor, BoxConstraints constraints) {
  return FutureBuilder<UserModel>(
    future: UserService().getUserById(post.userId),
    builder: (context, userSnapshot) {
      // Default values in case user data isn't loaded yet
      int helpCount = 0;
      int thankCount = 0;
      
      if (userSnapshot.hasData) {
        helpCount = userSnapshot.data!.helpCount;
        thankCount = userSnapshot.data!.thankCount;
      }
      
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
                // Increment view count and navigate - no need to check if viewer is post creator
                // since we've already filtered those out
                await PostService().incrementViewCount(post.id);

                // Navigate and wait for return
                await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                      PostDetailScreen(post: post),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );

                // Update state after navigation with proper delay
                if (mounted) {
                  // Add a short delay to ensure proper frame scheduling
                  await Future.delayed(const Duration(milliseconds: 100));
                  _loadPosts(); // Reload posts after coming back
                }
              },
              onLongPress: () => _showReportDialog(post), // Add this line
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
                      maxHeight: constraints.maxHeight, // Apply max height constraint
                    ),
                    child: SingleChildScrollView( // Add SingleChildScrollView to prevent overflow
                      physics: NeverScrollableScrollPhysics(), // Disable scrolling within the card
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Keep column as small as possible
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          // Post Image if available
                          if (post.images.isNotEmpty)
                            _buildPostImage(post, fontFamily, primaryColor),
                          
                          // Content section
                          Padding(
                            padding: EdgeInsets.all(post.images.isNotEmpty ? 14.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (post.images.isEmpty)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Spacer(),
                                      Text(
                                        _formatPostDate(post.createdAt),
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      // Add report button here when no image
                                      GestureDetector(
                                        onTap: () => _showReportDialog(post),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Icon(
                                            Icons.more_vert_rounded,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                
                                // User info row
                                buildUserInfoRow(post, helpCount, thankCount, fontFamily, primaryColor),
                                
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
    },
  );
}

// 4. Update the _buildPostImage method to include the report button
Widget _buildPostImage(PostModel post, String fontFamily, Color primaryColor) {
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
              const SizedBox(width: 8),
              // Add report button
              GestureDetector(
                onTap: () => _showReportDialog(post),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// 5. Add this new method to show the report dialog
void _showReportDialog(PostModel post) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => ReportDialog(
      postId: post.id,
      reportedUserId: post.userId,
      onReportSubmitted: () {
        // Optionally reload posts after report submission
        _loadPosts();
      },
    ),
  );
}

// Extract the user info row to a separate method
 Widget buildUserInfoRow(PostModel post, int helpCount, int thankCount, String fontFamily, Color primaryColor) {
    // Get the verification status from the cache
    final isVerified = _userVerificationStatus[post.userId] ?? false;
    
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
            backgroundImage: post.userImage.isNotEmpty ? NetworkImage(post.userImage) : null,
            child: post.userImage.isEmpty
                ? Text(
                    post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
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
        // Username and location
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
                  // Use the cached verification status instead of FutureBuilder
                  if (isVerified)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Colors.blue[600],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Not Verified',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 10,
                            color: Colors.grey[700],
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
          ],
        ),
      ],
    );
  }

// Extract the footer row to a separate method
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


// Helper widget with reduced size
Widget _buildStatBadge(IconData icon, int count, String fontFamily) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),  // Reduced padding
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6),  // Reduced radius
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),  // Reduced size
        const SizedBox(width: 3),  // Reduced spacing
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,  // Reduced size
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    ),
  );
}

// Helper widgets with reduced size
Widget _buildPostTypeBadge(PostType type, String fontFamily, Color primaryColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),  // Reduced padding
    decoration: BoxDecoration(
      color: type == PostType.offer 
          ? const Color(0xFF2E7D32).withOpacity(0.9) 
          : const Color(0xFF1565C0).withOpacity(0.9),
      borderRadius: BorderRadius.circular(10),  // Reduced radius
      boxShadow: [
        BoxShadow(
          color: (type == PostType.offer 
              ? const Color(0xFF2E7D32) 
              : const Color(0xFF1565C0)).withOpacity(0.2),
          blurRadius: 3,
          offset: const Offset(0, 1),
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
          size: 12,  // Reduced size
        ),
        const SizedBox(width: 4),  // Reduced spacing
        Text(
          type.toString().split('.').last.toUpperCase(),
          style: TextStyle(
            fontFamily: fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,  // Reduced size
          ),
        ),
      ],
    ),
  );
}

Widget _buildCategoryBadge(String category, String fontFamily, Color primaryColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),  // Reduced padding
    decoration: BoxDecoration(
      color: primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),  // Reduced radius
      border: Border.all(color: primaryColor.withOpacity(0.3)),
    ),
    child: Text(
      category,
      style: TextStyle(
        fontFamily: fontFamily,
        color: primaryColor,
        fontWeight: FontWeight.w500,
        fontSize: 10,  // Reduced size
      ),
    ),
  );
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

 

  @override
  bool get wantKeepAlive => true;
}