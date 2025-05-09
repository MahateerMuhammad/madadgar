import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/widgets/post_card.dart';
import 'package:madadgar/screens/post/post_detail_screen.dart';
import 'package:madadgar/config/theme.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  _NearbyScreenState createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  List<PostModel> _nearbyPosts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNearbyPosts();
  }

  Future<void> _loadNearbyPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final postService = Provider.of<PostService>(context, listen: false);

      final user = authService.currentUser;
      if (user == null || user.region.isEmpty) {
        throw Exception('User region not found.');
      }

      // Correct method call with named arguments
      final posts = await postService.getPostsByRegion(
        region: user.region, // Named parameter
      );

      setState(() {
        _nearbyPosts = posts;
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    final accentColor = HSLColor.fromColor(primaryColor).withLightness(0.85).toColor();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
     
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadNearbyPosts,
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
                        onPressed: _loadNearbyPosts,
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
                )
              : _nearbyPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No nearby posts found in your region',
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
                              'Be the first to post help offers or requests in your area!',
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
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: _nearbyPosts.length,
                        itemBuilder: (context, index) {
                          final post = _nearbyPosts[index];
                          
                          // We're not using PostCard directly to match the UI style
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
                                onTap: () {
                                  
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
                                                      post.type.name.toLowerCase() == 'offer' 
                                                          ? Icons.volunteer_activism 
                                                          : Icons.help_outline,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      post.type.name.toUpperCase(),
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
                    ),
      ),
    );
  }
}