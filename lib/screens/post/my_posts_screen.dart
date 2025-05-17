import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/widgets/post_card.dart';
import 'package:madadgar/screens/post/post_detail_screen.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/screens/post/edit_post_screen.dart';

class MyPostsScreen extends StatefulWidget {
  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  List<PostModel> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    try {
      setState(() => _isLoading = true);

      final postService = Provider.of<PostService>(context, listen: false);
      final posts = await postService.getUserPosts();

      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user posts: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading posts: $e',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _updatePostStatus(String postId, PostStatus newStatus) async {
    try {
      setState(() => _isLoading = true);
      
      final postService = Provider.of<PostService>(context, listen: false);
      final postIndex = _userPosts.indexWhere((post) => post.id == postId);
      
      if (postIndex != -1) {
        final updatedPost = _userPosts[postIndex].copyWith(status: newStatus);
        await postService.updatePost(updatedPost);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Post marked as ${newStatus.toString().split('.').last}',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
              ),
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        await _loadUserPosts();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating post status: $e',
            style: TextStyle(
              fontFamily: MadadgarTheme.fontFamily,
            ),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showStatusUpdateDialog(PostModel post) async {
    if (post.status != PostStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This post is already marked as ${post.status.toString().split('.').last}',
            style: TextStyle(
              fontFamily: MadadgarTheme.fontFamily,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Update Post Status',
          style: TextStyle(
            fontFamily: MadadgarTheme.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change the status of this post to:',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusOption(
              context,
              PostStatus.fulfilled,
              'Fulfilled',
              'Mark this post as fulfilled when your need has been met or your offer has been accepted.',
              Colors.green[700]!,
              Icons.check_circle_outline,
              post,
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context,
              PostStatus.closed,
              'Closed',
              'Mark this post as closed when you no longer want to receive responses.',
              Colors.grey[700]!,
              Icons.cancel_outlined,
              post,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    PostStatus status,
    String title,
    String description,
    Color color,
    IconData icon,
    PostModel post,
  ) {
    final primaryColor = MadadgarTheme.primaryColor;
    
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _updatePostStatus(post.id, status);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: MadadgarTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: MadadgarTheme.fontFamily,
                      color: Colors.grey[800],
                      fontSize: 12,
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

  Future<void> _deletePost(String postId) async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Delete Post?',
                style: TextStyle(
                  fontFamily: MadadgarTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this post? This action cannot be undone.',
                style: TextStyle(
                  fontFamily: MadadgarTheme.fontFamily,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontFamily: MadadgarTheme.fontFamily,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'DELETE',
                    style: TextStyle(
                      fontFamily: MadadgarTheme.fontFamily,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;

      // Show loading indicator
      setState(() => _isLoading = true);

      // Delete the post
      final postService = Provider.of<PostService>(context, listen: false);
      await postService.deletePost(postId);

      // Reload posts
      await _loadUserPosts();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post deleted successfully',
            style: TextStyle(
              fontFamily: MadadgarTheme.fontFamily,
            ),
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting post: $e',
            style: TextStyle(
              fontFamily: MadadgarTheme.fontFamily,
            ),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          'My Posts',
          style: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : _userPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.post_add,
                          size: 56,
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Posts Yet',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have not created any posts yet.',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserPosts,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    itemCount: _userPosts.length,
                    itemBuilder: (context, index) {
                      final post = _userPosts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Stack(
                          children: [
                            // Post Card
                            Hero(
                              tag: 'post_${post.id}',
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                elevation: 0,
                                child: InkWell(
                                  onTap: () {
                                    // Only navigate to edit screen if post is active
                                    if (post.status == PostStatus.active) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditPostScreen(post: post),
                                        ),
                                      ).then((_) => _loadUserPosts());
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  splashColor: post.status == PostStatus.active 
                                      ? primaryColor.withOpacity(0.05)
                                      : Colors.transparent,
                                  highlightColor: post.status == PostStatus.active
                                      ? primaryColor.withOpacity(0.05)
                                      : Colors.transparent,
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Post Image if available
                                          if (post.images.isNotEmpty)
                                            Stack(
                                              children: [
                                                Container(
                                                  height: 200,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: primaryColor.withOpacity(0.1),
                                                  ),
                                                  child: post.images.isNotEmpty
                                                      ? Image.network(
                                                          post.images.first,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Center(
                                                              child: CircularProgressIndicator(
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                                        loadingProgress.expectedTotalBytes!
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
                                                      : null,
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
                                                
                                                // Status badge for non-active posts (on image)
                                                if (post.status != PostStatus.active)
                                                  Positioned(
                                                    top: 12,
                                                    left: 12,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: post.status == PostStatus.fulfilled
                                                            ? Colors.green[700]!.withOpacity(0.9)
                                                            : Colors.grey[700]!.withOpacity(0.9),
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.2),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            post.status == PostStatus.fulfilled
                                                                ? Icons.check_circle_outline
                                                                : Icons.cancel_outlined,
                                                            color: Colors.white,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            post.status.toString().split('.').last.toUpperCase(),
                                                            style: TextStyle(
                                                              fontFamily: fontFamily,
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),

                                          // Content
                                          Padding(
                                            padding: EdgeInsets.all(post.images.isNotEmpty ? 16.0 : 20.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (post.images.isEmpty)
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      // Status badge for non-active posts (if no image)
                                                      if (post.status != PostStatus.active)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: post.status == PostStatus.fulfilled
                                                                ? Colors.green[700]!.withOpacity(0.9)
                                                                : Colors.grey[700]!.withOpacity(0.9),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                post.status == PostStatus.fulfilled
                                                                    ? Icons.check_circle_outline
                                                                    : Icons.cancel_outlined,
                                                                color: Colors.white,
                                                                size: 14,
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Text(
                                                                post.status.toString().split('.').last.toUpperCase(),
                                                                style: TextStyle(
                                                                  fontFamily: fontFamily,
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 12,
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

                                                const SizedBox(height: 12),

                                                // Post badges (type & category)
                                                Row(
                                                  children: [
                                                    // Post type badge
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: post.type == PostType.offer
                                                            ? const Color(0xFF2E7D32).withOpacity(0.9)
                                                            : const Color(0xFF1565C0).withOpacity(0.9),
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: (post.type == PostType.offer
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
                                                            post.type == PostType.offer
                                                                ? Icons.volunteer_activism_rounded
                                                                : Icons.help_outline_rounded,
                                                            color: Colors.white,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            post.type.toString().split('.').last.toUpperCase(),
                                                            style: TextStyle(
                                                              fontFamily: fontFamily,
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Category badge
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: primaryColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                                                      ),
                                                      child: Text(
                                                        post.category,
                                                        style: TextStyle(
                                                          fontFamily: fontFamily,
                                                          color: primaryColor,
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 14),

                                                // Post title
                                                Text(
                                                  post.title,
                                                  style: TextStyle(
                                                    fontFamily: fontFamily,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black.withOpacity(0.85),
                                                    height: 1.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 10),

                                                // Post description
                                                Text(
                                                  post.description,
                                                  style: TextStyle(
                                                    fontFamily: fontFamily,
                                                    fontSize: 14,
                                                    color: Colors.black.withOpacity(0.65),
                                                    height: 1.5,
                                                  ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),

                                                const SizedBox(height: 16),

                                                // Footer with view count and edit hint
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // View count
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.visibility_rounded,
                                                          size: 16,
                                                          color: Colors.grey[600],
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${post.viewCount} ${post.viewCount == 1 ? 'view' : 'views'}',
                                                          style: TextStyle(
                                                            fontFamily: fontFamily,
                                                            fontSize: 13,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Tap to edit hint - only show if post is active
                                                    if (post.status == PostStatus.active)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                        decoration: BoxDecoration(
                                                          color: primaryColor.withOpacity(0.07),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.edit_rounded,
                                                              size: 14,
                                                              color: primaryColor,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Tap to edit',
                                                              style: TextStyle(
                                                                fontFamily: fontFamily,
                                                                fontSize: 12,
                                                                color: primaryColor,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
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
                                ),
                              ),
                            ),

                            // Menu button
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: PopupMenuButton<String>(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  itemBuilder: (BuildContext context) {
                                    List<PopupMenuEntry<String>> items = [
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.red[700],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                fontFamily: fontFamily,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ];
                                    
                                    // Only add status update options if post is active
                                    if (post.status == PostStatus.active) {
                                      items.add(
                                        PopupMenuItem<String>(
                                          value: 'status',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.update,
                                                color: primaryColor,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Update Status',
                                                style: TextStyle(
                                                  fontFamily: fontFamily,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                      
                                      
                                    }

                                   
                                    
                                    return items;
                                  },
                                  onSelected: (String value) {
                                    switch (value) {
                                      case 'status':
                                        _showStatusUpdateDialog(post);
                                        break;
                                     
                                      case 'delete':
                                        _deletePost(post.id);
                                        break;
                                      case 'view':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PostDetailScreen(post: post),
                                          ),
                                        );
                                        break;
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}