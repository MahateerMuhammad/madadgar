// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:madadgar/models/post.dart';
// import 'package:madadgar/services/post_service.dart';

// class PostDetailScreen extends StatefulWidget {
//   final String postId;

//   const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

//   @override
//   _PostDetailScreenState createState() => _PostDetailScreenState();
// }

// class _PostDetailScreenState extends State<PostDetailScreen> {
//   late Future<PostModel> _postFuture;

//   @override
//   void initState() {
//     super.initState();
//     _postFuture = Provider.of<PostService>(context, listen: false).getPostById(widget.postId);
//   }

//   Future<void> _deletePost() async {
//     final postService = Provider.of<PostService>(context, listen: false);
//     await postService.deletePost(widget.postId);
//     if (mounted) {
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Post deleted successfully')),
//       );
//     }
//   }

//   Future<void> _togglePostStatus(PostModel post) async {
//     final postService = Provider.of<PostService>(context, listen: false);
//     final newStatus = post.status == PostStatus.active ? PostStatus.closed : PostStatus.active;

//     await postService.updatePostStatus(widget.postId, newStatus);

//     setState(() {
//       _postFuture = postService.getPostById(widget.postId);
//     });

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Post status changed to ${newStatus.name}')),
//       );
//     }
//   }

//   Future<void> _sharePost(PostModel post) async {
//     try {
//       final String postType = post.type == PostType.need ? 'needs help with' : 'is offering';
//       final String shareText =
//           'Check out this post on Madadgar: ${post.userName} $postType ${post.title} in ${post.region}. Open Madadgar app to respond.';
//       Share.share(shareText);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sharing post: ${e.toString()}')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Post Details')),
//       body: FutureBuilder<PostModel>(
//         future: _postFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData) {
//             return const Center(child: Text('Post not found'));
//           }

//           final post = snapshot.data!;

//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Post Title
//                 Text(post.title, style: Theme.of(context).textTheme.headline6),
//                 const SizedBox(height: 8),

//                 // Post Description
//                 Text(post.description),
//                 const SizedBox(height: 16),

//                 // Post Details
//                 Text('Posted by: ${post.userName}'),
//                 Text('Region: ${post.region}'),
//                 Text('Status: ${post.status.name.toUpperCase()}'),
//                 const SizedBox(height: 20),

//                 // Action Buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     ElevatedButton.icon(
//                       onPressed: () => _togglePostStatus(post),
//                       icon: Icon(post.status == PostStatus.active ? Icons.close : Icons.check),
//                       label: Text(post.status == PostStatus.active ? 'Mark as Closed' : 'Reopen'),
//                     ),
//                     ElevatedButton.icon(
//                       onPressed: () => _sharePost(post),
//                       icon: const Icon(Icons.share),
//                       label: const Text('Share'),
//                     ),
//                     ElevatedButton.icon(
//                       onPressed: _deletePost,
//                       icon: const Icon(Icons.delete),
//                       label: const Text('Delete'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Enum-safe parsing helpers
// PostType _mapStringToType(String? type) {
//   switch (type) {
//     case 'offer':
//       return PostType.offer;
//     case 'need':
//     default:
//       return PostType.need;
//   }
// }

// PostStatus _mapStringToStatus(String? status) {
//   switch (status) {
//     case 'closed':
//       return PostStatus.closed;
//     case 'active':
//     default:
//       return PostStatus.active;
//   }
// }

// // Updated PostModel for reference
// class PostModel {
//   final String id;
//   final String title;
//   final String description;
//   final PostType type;
//   final PostStatus status;
//   final String userName;
//   final String region;

//   PostModel({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.type,
//     required this.status,
//     required this.userName,
//     required this.region,
//   });

//   factory PostModel.fromMap(String id, Map<String, dynamic> map) {
//     return PostModel(
//       id: id,
//       title: map['title'] ?? '',
//       description: map['description'] ?? '',
//       type: _mapStringToType(map['type']),
//       status: _mapStringToStatus(map['status']),
//       userName: map['userName'] ?? '',
//       region: map['region'] ?? '',
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'title': title,
//       'description': description,
//       'type': type.name,
//       'status': status.name,
//       'userName': userName,
//       'region': region,
//     };
//   }
// }

// enum PostType { need, offer }
// enum PostStatus { active, closed }