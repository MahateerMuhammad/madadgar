import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/widgets/post_card.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  _NearbyScreenState createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  List<PostModel> _nearbyPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyPosts();
  }

  Future<void> _loadNearbyPosts() async {
    try {
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nearbyPosts.isEmpty
              ? const Center(child: Text('No nearby posts found'))
              : ListView.builder(
                  itemCount: _nearbyPosts.length,
                  itemBuilder: (context, index) {
                    final post = _nearbyPosts[index];
                    return PostCard(
                      post: post,
                      onTap: () {
                        // Navigate to post details if needed
                      },
                    );
                  },
                ),
    );
  }
}
