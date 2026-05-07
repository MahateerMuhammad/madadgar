import 'package:flutter/material.dart';
import 'package:***REMOVED***/screens/auth/login_screen.dart';
// Import other screens as you implement them
import 'package:***REMOVED***/screens/auth/register_screen.dart';
// import 'package:***REMOVED***/screens/auth/verify_screen.dart';
import 'package:***REMOVED***/screens/auth/forgot_screen_password.dart';
import 'package:***REMOVED***/screens/home/home_screen.dart';
import 'package:***REMOVED***/screens/post/create_post_screen.dart';
 //import 'package:***REMOVED***/screens/post/post_detail_screen.dart';
// import 'package:***REMOVED***/screens/post/my_posts_screen.dart';
import 'package:***REMOVED***/screens/profile/profile_screen.dart';

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
    forgotPassword: (context) =>  const ForgetPasswordScreen(),
    home: (context) => const HomeScreen(),
     createPost: (context) => const CreatePostScreen(),
    // postDetail: (context) => PostDetailScreen(),
    //myPosts: (context) => MyPostsScreen(),
    profile: (context) => const ProfileScreen(),
  };
}
