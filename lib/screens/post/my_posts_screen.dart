// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:madadgar/config/theme.dart';
// import 'package:madadgar/models/post.dart';
// import 'package:madadgar/services/auth_service.dart';
// import 'package:madadgar/services/post_service.dart';
// import 'package:madadgar/widgets/custom_button.dart';
// import 'package:madadgar/screens/post_detail_screen.dart';

// class MyPostsScreen extends StatefulWidget {
//   const MyPostsScreen({Key? key}) : super(key: key);

//   @override
//   _MyPostsScreenState createState() => _MyPostsScreenState();
// }

// class _MyPostsScreenState extends State<MyPostsScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   late Future<List<PostModel>> _postsFuture;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadPosts();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   void _loadPosts() {
//     final authService = Provider.of<AuthService>(context, listen: false);
//     final postService = Provider.of<PostService>(context, listen: false);
    
//     final userId = authService.currentUser?.id;
//     if (userId != null) {
//       _postsFuture = postService.getUserPosts(userId);
//     } else {
//       _postsFuture = Future.value([]);
//     }
//   }

//   Future<void> _refreshPosts() async {
//     setState(() {
//       _loadPosts();
//     });
//     return Future.delayed(const Duration(milliseconds: 500));
//   }

//   Widget _buildPostCard(PostModel post) {
//     final dateFormat = DateFormat('MMM d, yyyy');
    
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: () async {
//           final result = await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PostDetailScreen(postId: post.id),
//             ),
//           );
          
//           // Refresh posts if post was updated or deleted
//           if (result == true) {
//             _refreshPosts();
//           }
//         },
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header with type badge and status
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: post.type == PostType.need
//                           ? MadadgarTheme.needColor.withOpacity(0.1)
//                           : MadadgarTheme.offerColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: post.type == PostType.need
//                             ? MadadgarTheme.needColor
//                             : MadadgarTheme.offerColor,
//                       ),
//                     ),
//                     child: Text(
//                       post.type == PostType.need ? 'NEED' : 'OFFER',
//                       style: TextStyle(
//                         color: post.type == PostType.need
//                             ? MadadgarTheme.needColor
//                             : MadadgarTheme.offerColor,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                   _buildStatusBadge(post.status),
//                 ],
//               ),
              
//               const SizedBox(height: 12),
              
//               // Title
//               Text(
//                 post.title,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
              
//               const SizedBox(height: 8),
              
//               // Category and Region
//               Row(
//                 children: [
//                   const Icon(Icons.category, size: 16, color: Colors.grey),
//                   const SizedBox(width: 4),
//                   Text(
//                     post.category,
//                     style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                   const SizedBox(width: 16),
//                   const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       post.region,
//                       style: const TextStyle(color: Colors.grey, fontSize: 12),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 12),
              
//               // Date and Stats
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     dateFormat.format(post.createdAt),
//                     style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                   Row(
//                     children: [
//                       const Icon(Icons.visibility, size: 14, color: Colors.grey),
//                       const SizedBox(width: 2),
//                       Text(
//                         '${post.viewCount}',
//                         style: const TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                       const SizedBox(width: 10),
//                       const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
//                       const SizedBox(width: 2),
//                       Text(
//                         '${post.respondCount}',
//                         style: const TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildStatusBadge(PostStatus status) {
//     Color color;
//     String label;
    
//     switch (status) {
//       case PostStatus.active:
//         color = MadadgarTheme.primaryColor;
//         label = 'Active';
//         break;
//       case PostStatus.fulfilled:
//         color = MadadgarTheme.offerColor;
//         label = 'Fulfilled';
//         break;
//       case PostStatus.closed:
//         color = Colors.grey;
//         label = 'Closed';
//         break;
//     }
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontWeight: FontWeight.bold,
//           fontSize: 10,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Posts'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'All'),
//             Tab(text: 'Needs'),
//             Tab(text: 'Offers'),
//           ],
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: _refreshPosts,
//               child: FutureBuilder<List<PostModel>>(
//                 future: _postsFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
                  
//                   if (snapshot.hasError) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.error_outline, size: 48, color: Colors.grey),
//                           const SizedBox(height: 16),
//                           Text('Error: ${snapshot.error}'),
//                           const SizedBox(height: 16),
//                           CustomButton(
//                             label: 'Retry',
//                             onPressed: _refreshPosts,
//                             backgroundColor: MadadgarTheme.primaryColor,
//                           ),
//                         ],
//                       ),
//                     );
//                   }
                  
//                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.post_add, size: 48, color: Colors.grey),
//                           const SizedBox(height: 16),
//                           const Text('You have not created any posts yet'),
//                           const SizedBox(height: 16),
//                           CustomButton(
//                             label: 'Create Post',
//                             onPressed: () {
//                               // Navigate to create post screen
//                               Navigator.pushNamed(context, '/create-post');
//                             },
//                             backgroundColor: MadadgarTheme.primaryColor,
//                           ),
//                         ],
//                       ),
//                     );
//                   }
                  
//                   final allPosts = snapshot.data!;
//                   final needPosts = allPosts.where((post) => post.type == PostType.need).toList();
//                   final offerPosts = allPosts.where((post) => post.type == PostType.offer).toList();
                  
//                   return TabBarView(
//                     controller: _tabController,
//                     children: [
//                       // All Posts Tab
//                       _buildPostList(allPosts),
                      
//                       // Needs Tab
//                       _buildPostList(needPosts),
                      
//                       // Offers Tab
//                       _buildPostList(offerPosts),
//                     ],
//                   );
//                 },
//               ),
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Navigate to create post screen
//           Navigator.pushNamed(context, '/create-post');
//         },
//         backgroundColor: MadadgarTheme.primaryColor,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
  
//   Widget _buildPostList(List<PostModel> posts) {
//     if (posts.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.info_outline, size: 48, color: Colors.grey),
//             const SizedBox(height: 16),
//             const Text('No posts found in this category'),
//           ],
//         ),
//       );
//     }
    
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: posts.length,
//       itemBuilder: (context, index) {
//         return _buildPostCard(posts[index]);
//       },
//     );
//   }
// }