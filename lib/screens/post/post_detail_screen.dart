import 'package:flutter/material.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/widgets/post_detail_chat.dart'; // Import PostDetailChatWidget

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late int _viewCount;
  final ScrollController _scrollController = ScrollController();
  bool _showChatWidget = false; // Added to toggle chat widget visibility

  @override
  void initState() {
    super.initState();
    _viewCount = widget.post.viewCount;
    _fetchViewCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchViewCount() async {
    final postService = Provider.of<PostService>(context, listen: false);
    final viewCount = await postService.getViewCount(widget.post.id);
    setState(() {
      _viewCount = viewCount;
    });
  }

  void _toggleChatWidget() {
    setState(() {
      _showChatWidget = !_showChatWidget;
    });
    
    // Scroll to the bottom to show the chat widget if it's visible
    if (_showChatWidget) {
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final primaryColor = MadadgarTheme.primaryColor;
    final theme = Theme.of(context);
    final secondaryColor = primaryColor.withOpacity(0.1);
    final accentColor = HSLColor.fromColor(primaryColor).withLightness(0.85).toColor();
    final fontFamily = MadadgarTheme.fontFamily;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom App Bar - simplified without image handling
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    post.title,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post metadata row with design elements
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: accentColor),
                    ),
                    child: Row(
                      children: [
                        // Type badge with icon
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                post.type.name.toLowerCase() == 'offer' 
                                    ? Icons.volunteer_activism 
                                    : Icons.help_outline,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                post.type.name.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        // Category pill
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            post.category,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Spacer(),
                        // Timestamp with icon
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                timeago.format(post.createdAt),
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // User profile card with pattern
                  Container(
                    padding: EdgeInsets.all(16),
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
                      image: DecorationImage(
                        image: AssetImage('assets/images/pattern.png'),
                        opacity: 0.05,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: post.userImage.isNotEmpty ? NetworkImage(post.userImage) : null,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: post.userImage.isEmpty ? Icon(Icons.person, color: primaryColor) : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.userName,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    post.region,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Stats in vertical layout
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.visibility, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  '$_viewCount',
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    color: Colors.grey, 
                                    fontSize: 14
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  '${post.respondCount}',
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    color: Colors.grey, 
                                    fontSize: 14
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Description section with decorative elements
                  Row(
                    children: [
                      Container(
                        height: 24,
                        width: 4,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Decorative quote marks
                        Row(
                          children: [
                            Icon(Icons.format_quote, 
                              color: primaryColor.withOpacity(0.2), 
                              size: 32
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          post.description,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Display the chat widget if toggled
                  if (_showChatWidget)
                    PostDetailChatWidget(post: post),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom action bar with multiple options
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              SizedBox(width: 12),
              // Respond button
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, HSLColor.fromColor(primaryColor).withLightness(0.4).toColor()],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Toggle the chat widget when the user clicks respond
                        _toggleChatWidget();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showChatWidget 
                                  ? Icons.close 
                                  : Icons.chat_bubble_outline, 
                              color: Colors.white
                            ),
                            SizedBox(width: 8),
                            Text(
                              _showChatWidget ? 'Cancel' : 'Respond',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}