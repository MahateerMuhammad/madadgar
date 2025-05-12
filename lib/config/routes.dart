import 'package:flutter/material.dart';
import 'package:madadgar/screens/auth/login_screen.dart';
// Import other screens as you implement them
import 'package:madadgar/screens/auth/register_screen.dart';
// import 'package:madadgar/screens/auth/verify_screen.dart';
import 'package:madadgar/screens/auth/forgot_screen_password.dart';
import 'package:madadgar/screens/home/home_screen.dart';
import 'package:madadgar/screens/post/create_post_screen.dart';
 import 'package:madadgar/screens/post/post_detail_screen.dart';
// import 'package:madadgar/screens/post/my_posts_screen.dart';
import 'package:madadgar/screens/profile/profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  // Define other routes as you implement them
  static const String register = '/register';
  // static const String verify = '/verify';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String createPost = '/create-post';
   static const String postDetail = '/post-detail';
   static const String myPosts = '/my-posts';
   static const String profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    login: (context) =>const LoginScreen(),
    // Add other routes here as you implement them
    register: (context) => const RegisterScreen(),
    // verify: (context) => VerifyScreen(),
    forgotPassword: (context) =>   ForgetPasswordScreen(),
    home: (context) => HomeScreen(),
     createPost: (context) => CreatePostScreen(),
    // postDetail: (context) => PostDetailScreen(),
    //myPosts: (context) => MyPostsScreen(),
    profile: (context) => ProfileScreen(),
  };
}
