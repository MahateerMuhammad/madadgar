import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/screens/post/post_detail_screen.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onTap;
  final String? currentUserId; // optional

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.currentUserId, // not required
  });


 

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _viewCount;

  @override
  void initState() {
    super.initState();
    _viewCount = widget.post.viewCount;
  }

   
void _handleTap(BuildContext context) async {
  final postService = Provider.of<PostService>(context, listen: false);
  final viewerId = widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
  

  if (viewerId != null && viewerId != widget.post.userId) {
    await postService.incrementViewCount(widget.post.id);
    setState(() {
      _viewCount++;
    });
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PostDetailScreen(post: widget.post),
    ),
  );
}




  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final color = post.type == PostType.need
        ? const Color(0xFFE57373)
        : const Color(0xFF81C784);
    final labelText = post.type == PostType.need ? 'NEED' : 'OFFER';
    final labelIcon =
        post.type == PostType.need ? Icons.help_outline : Icons.volunteer_activism;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.images.isNotEmpty)
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    post.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 32),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(labelIcon, size: 14, color: color),
                              const SizedBox(width: 4),
                              Text(
                                labelText,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            post.category,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.description.length > 120
                          ? '${post.description.substring(0, 120)}...'
                          : post.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildUserAvatar(),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  post.userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildStatItem(Icons.visibility_outlined, _viewCount),
                            const SizedBox(width: 12),
                            _buildStatItem(Icons.chat_bubble_outline_rounded, post.respondCount),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (post.region.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            post.region,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
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

  Widget _buildUserAvatar() {
    final post = widget.post;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: post.type == PostType.need
            ? const Color(0xFFE57373).withOpacity(0.2)
            : const Color(0xFF81C784).withOpacity(0.2),
        image: post.userImage.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(post.userImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: post.userImage.isEmpty
          ? Icon(
              Icons.person,
              size: 16,
              color: post.type == PostType.need
                  ? const Color(0xFFE57373)
                  : const Color(0xFF81C784),
            )
          : null,
    );
  }

  Widget _buildStatItem(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
