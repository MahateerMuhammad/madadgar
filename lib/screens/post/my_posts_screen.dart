import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/widgets/post_card.dart';
import 'package:madadgar/screens/post/post_detail_screen.dart';

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
      final postService = Provider.of<PostService>(context, listen: false);
      final posts = await postService.getUserPosts();

      setState(() {
        _userPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading user posts: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Posts')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userPosts.isEmpty
              ? Center(child: Text('You have not created any posts yet.'))
              : RefreshIndicator(
                  onRefresh: _loadUserPosts,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _userPosts.length,
                    itemBuilder: (context, index) {
                      final post = _userPosts[index];
                      return PostCard(
                        post: post,
                       onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: post),
                          ),
                        );
                      },

                      );
                    },
                  ),
                ),
    );
  }
}
