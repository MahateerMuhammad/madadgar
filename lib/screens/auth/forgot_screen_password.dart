import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/config/theme.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // Clear previous messages
    setState(() {
      _message = null;
      _isSuccess = false;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _message = 'Password reset email sent successfully';
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = _getReadableErrorMessage(e.toString());
        _isSuccess = false;
        _isLoading = false;
      });
    }
  }

  String _getReadableErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No user found with this email';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email format';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Check your connection';
    }
    return 'Failed to send reset email. Please try again';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Reset Password",
          style: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 50,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Enter your email to reset your password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(
                        Icons.email_outlined, 
                        color: primaryColor,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, 
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Reset Password Button
                  ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Reset Password',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Message Display
                  if (_message != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12, 
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _isSuccess 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSuccess 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess 
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                            color: _isSuccess ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isSuccess ? Colors.green : Colors.red,
                                fontSize: 14,
                                fontFamily: fontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }
}