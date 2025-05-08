// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:madadgar/config/routes.dart';
// import 'package:madadgar/services/auth_service.dart';
// import 'package:madadgar/widgets/custom_button.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class VerifyScreen extends StatefulWidget {
//   @override
//   _VerifyScreenState createState() => _VerifyScreenState();
// }

// class _VerifyScreenState extends State<VerifyScreen> {
//   bool _isLoading = false;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isEmailVerified = false;

//   @override
//   void initState() {
//     super.initState();
//     // Check if user's email is already verified
//     _checkEmailVerified();
//   }

//   Future<void> _checkEmailVerified() async {
//     final user = _auth.currentUser;
//     if (user != null) {
//       await user.reload();
//       setState(() {
//         _isEmailVerified = user.emailVerified;
//       });

//       if (_isEmailVerified) {
//         // If email is verified, navigate to home screen
//         _navigateToHome();
//       }
//     }
//   }

//   Future<void> _resendVerificationEmail() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         await user.sendEmailVerification();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Verification email resent successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to resend verification email: ${e.toString()}'),
//           backgroundColor: Theme.of(context).colorScheme.error,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _navigateToHome() {
//     Navigator.pushReplacementNamed(context, AppRoutes.home);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verify Email'),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Icon
//                 Icon(
//                   Icons.mark_email_read,
//                   size: 80,
//                   color: Theme.of(context).primaryColor,
//                 ),
//                 const SizedBox(height: 24),
                
//                 // Title
//                 Text(
//                   'Verify Your Email',
//                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Description
//                 Text(
//                   'We have sent a verification email to ${_auth.currentUser?.email}.\n\nPlease check your email and click the link to verify your account.',
//                   style: Theme.of(context).textTheme.bodyLarge,
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 32),
                
//                 // Verification status
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: _isEmailVerified ? Colors.green.shade100 : Colors.amber.shade100,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         _isEmailVerified ? Icons.check_circle : Icons.info,
//                         color: _isEmailVerified ? Colors.green : Colors.amber,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Text(
//                           _isEmailVerified
//                               ? 'Email verified successfully!'
//                               : 'Email not verified yet. Check your inbox or spam folder.',
//                           style: TextStyle(
//                             color: _isEmailVerified ? Colors.green : Colors.amber.shade900,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 32),
                
//                 // Buttons
//                 if (!_isEmailVerified) ...[
//                   CustomButton(
//                     text: 'Resend Verification Email',
//                     isLoading: _isLoading,
//                     onPressed: _resendVerificationEmail,
//                   ),
//                   const SizedBox(height: 16),
//                   CustomButton(
//                     text: 'I\'ve Verified My Email',
//                     isLoading: false,
//                     onPressed: _checkEmailVerified,
//                     color: Theme.of(context).colorScheme.secondary,
//                   ),
//                 ] else ...[
//                   CustomButton(
//                     text: 'Continue to Home',
//                     isLoading: false,
//                     onPressed: _navigateToHome,
//                   ),
//                 ],
//                 const SizedBox(height: 16),
                
//                 // Logout option
//                 TextButton(
//                   onPressed: () {
//                     Provider.of<AuthService>(context, listen: false).logout();
//                     Navigator.pushReplacementNamed(context, AppRoutes.login);
//                   },
//                   child: const Text('Logout'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
