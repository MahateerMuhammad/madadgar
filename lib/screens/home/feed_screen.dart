import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/config/constants.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/widgets/post_card.dart';

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
                  _buildHeader(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isFilterExpanded ? null : 0,
                    child: _buildExpandedFilters(),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: MadadgarTheme.primaryColor,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        _loadPosts();
                      },
                      child: FutureBuilder<List<PostModel>>(
                        future: _postsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildLoadingState();
                          }
                          
                          if (snapshot.hasError) {
                            return _buildErrorState();
                          }
                          
                          final posts = snapshot.data ?? [];
                          
                          if (posts.isEmpty) {
                            return _buildEmptyState();
                          }
                          
                          return _buildPostsList(posts);
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

  Widget _buildHeader() {
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
                  _buildTypeFilter(null, 'All'),
                  const SizedBox(width: 8),
                  _buildTypeFilter(PostType.need, 'Needs'),
                  const SizedBox(width: 8),
                  _buildTypeFilter(PostType.offer, 'Offers'),
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



  Widget _buildTypeFilter(PostType? type, String label) {
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
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedFilters() {
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
              _buildCategoryChip('All'),
              ...AppConstants.categories.map((category) => _buildCategoryChip(category)),
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
              child: const Text('Reset Filters', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
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
            color: isSelected ? MadadgarTheme.primaryColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(MadadgarTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.signal_wifi_connected_no_internet_4_rounded,
                size: 32,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load feed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: MadadgarTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(120, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Icon(
                Icons.post_add_outlined,
                size: 36,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No posts available',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != 'All' || _selectedType != null
                  ? 'Try changing your filters'
                  : 'Be the first to create a post',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedCategory != 'All' || _selectedType != null)
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _selectedType = null;
                        _loadPosts();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Clear Filters'),
                  ),
                if (_selectedCategory != 'All' || _selectedType != null)
                  const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/create-post');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MadadgarTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Create Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(List<PostModel> posts) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 88),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          child: _buildPostCard(posts[index]),
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/post-detail',
          arguments: post.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PostCard(post: post, onTap: () {}),
        ),
      ),
    );
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