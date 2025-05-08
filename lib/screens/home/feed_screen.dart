import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/config/constants.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/screens/post/post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AutomaticKeepAliveClientMixin {
  late Future<List<PostModel>> _postsFuture;
  String _selectedCategory = 'All';
  PostType? _selectedType;
  final ScrollController _scrollController = ScrollController();
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadPosts() {
    final postService = Provider.of<PostService>(context, listen: false);
    setState(() {
      _postsFuture = postService.getPosts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        type: _selectedType,
        status: PostStatus.active,
      );
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
        backgroundColor: Colors.grey[50],
       
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(fontFamily),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isFilterExpanded ? null : 0,
                    child: _buildExpandedFilters(fontFamily),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: primaryColor,
                      backgroundColor: Colors.white,
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
                          
                          return _buildPostsList(posts, fontFamily, primaryColor);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              _buildFabButton(),
            ],
          ),
        ),
      ),
    );
  }

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
              Row(
                children: [
                  _buildTypeFilter(null, 'All', fontFamily),
                  const SizedBox(width: 8),
                  _buildTypeFilter(PostType.need, 'Needs', fontFamily),
                  const SizedBox(width: 8),
                  _buildTypeFilter(PostType.offer, 'Offers', fontFamily),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isFilterExpanded = !_isFilterExpanded;
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
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
              Icons.error_outline,
              size: 60,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load feed',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      ),
    );
  }

  Widget _buildEmptyState(String fontFamily, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.post_add,
            size: 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No posts found',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _selectedCategory != 'All' || _selectedType != null
                  ? 'Try changing your filters'
                  : 'Be the first to create a post',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<PostModel> posts, String fontFamily, Color primaryColor) {
    final accentColor = HSLColor.fromColor(primaryColor).withLightness(0.85).toColor();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          
          return Container(
            margin: EdgeInsets.only(bottom: 16),
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
              border: Border.all(color: accentColor.withOpacity(0.5)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: post),
                    ),
                  );
              },

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Image if available
                    if (post.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          post.images.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 120,
                              color: primaryColor.withOpacity(0.1),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: primaryColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                        ),
                      ),
                      
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User info row
                          Row(
                            children: [
                              CircleAvatar(
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
                                      ),
                                    )
                                  : null,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.userName,
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      post.region,
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatPostDate(post.createdAt),
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          
                          // Title
                          Text(
                            post.title,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          
                          // Description preview
                          Text(
                            post.description,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 16),
                          
                          // Metadata row
                          Row(
                            children: [
                              // Type badge with icon
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      post.type == PostType.offer 
                                          ? Icons.volunteer_activism 
                                          : Icons.help_outline,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      post.type.toString().split('.').last.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              
                              // Category pill
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  post.category,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Spacer(),
                              
                              // Stats
                              Row(
                                children: [
                                  Icon(Icons.visibility, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    '${post.viewCount}',
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    '${post.respondCount}',
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
        },
      ),
    );
  }

  String _formatPostDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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

  Widget _buildFabButton() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MadadgarTheme.primaryColor,
              Color.lerp(MadadgarTheme.primaryColor, Colors.black, 0.1)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MadadgarTheme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/create-post');
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.1),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}