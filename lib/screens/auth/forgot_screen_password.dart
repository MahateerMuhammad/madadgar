// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:madadgar/config/routes.dart';
// import 'package:madadgar/services/auth_service.dart';
// import 'package:madadgar/widgets/custom_button.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   @override
//   _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   bool _isLoading = false;
//   bool _emailSent = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }

//   Future<void> _resetPassword() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final authService = Provider.of<AuthService>(context, listen: false);
//       await authService.resetPassword(_emailController.text.trim());
      
//       setState(() {
//         _emailSent = true;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send reset email: ${e.toString()}'),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Forgot Password'),
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
//                   Icons.lock_reset,
//                   size: 80,
//                   color: Theme.of(context).primaryColor,
//                 ),
//                 const SizedBox(height: 24),
                
//                 // Title
//                 Text(
//                   'Reset Your Password',
//                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
                
//                 if (!_emailSent) ...[
//                   // Description
//                   Text(
//                     'Enter your email address below and we\'ll send you a link to reset your password.',
//                     style: Theme.of(context).textTheme.bodyLarge,
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 32),
                  
//                   // Form
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         TextFormField(
//                           controller: _emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           decoration: const InputDecoration(
//                             labelText: 'Email',
//                             prefixIcon: Icon(Icons.email),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your email';
//                             }
//                             if (!value.contains('@')) {
//                               return 'Please enter a valid email';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 24),
                        
//                         CustomButton(
//                           text: 'Send Reset Link',
//                           isLoading: _isLoading,
//                           onPressed: _resetPassword,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ] else ...[
//                   // Email sent confirmation
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       children: [
//                         const Icon(
//                           Icons.check_circle,
//                           color: Colors.green,
//                           size: 48,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Password reset link sent!',
//                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green.shade800,
//                               ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'We\'ve sent a password reset link to ${_emailController.text}. Please check your email to reset your password.',
//                           style: TextStyle(
//                             color: Colors.green.shade800,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),
                  
//                   CustomButton(
//                     text: 'Back to Login',
//                     isLoading: false,
//                     onPressed: () {
//                       Navigator.pushReplacementNamed(context, AppRoutes.login);
//                     },
//                   ),
//                 ],
                
//                 const SizedBox(height: 24),
                
//                 // Back to login option
//                 if (!_emailSent)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text('Remember your password?'),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushReplacementNamed(context, AppRoutes.login);
//                         },
//                         child: const Text('Login'),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }