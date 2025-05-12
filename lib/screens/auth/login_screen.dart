import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/config/routes.dart';
import 'package:madadgar/screens/auth/forgot_screen_password.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getReadableErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getReadableErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No user found with this email';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email format';
    } else if (error.contains('user-disabled')) {
      return 'This account has been disabled';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Check your connection';
    }
    return 'Login failed. Please try again';
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.register);
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgetPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isNarrow = screenWidth < 360;
    final primaryColor = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Decorative background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPatternPainter(
                primaryColor: primaryColor,
                isDarkMode: isDark,
              ),
            ).animate(controller: _animationController)
              .fadeIn(duration: 1200.ms, curve: Curves.easeOut),
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 600 ? screenWidth * 0.2 : 24.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top decoration with community illustration
                      SizedBox(
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background glow
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.3),
                                    primaryColor.withOpacity(0.0),
                                  ],
                                  stops: const [0.2, 1.0],
                                ),
                              ),
                            ).animate(controller: _animationController)
                              .scale(begin: Offset(0.5, 0.5), end: Offset(1.0, 1.0), duration: 800.ms, curve: Curves.elasticOut),
                            
                            // Logo container with styled border
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black12 : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                                ],
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.volunteer_activism,
                                size: 50,
                                color: primaryColor,
                              ),
                            ).animate(controller: _animationController)
                              .fadeIn(duration: 800.ms)
                              .scale(begin: Offset(0.7, 0.7), end: Offset(1.0, 1.0), duration: 800.ms, curve: Curves.elasticOut),
                            
                            // Small floating elements around the logo
                            ..._buildFloatingElements(primaryColor, isDark),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Welcome Text with Enhanced Animation
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ).animate(controller: _animationController)
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .moveY(begin: 30, end: 0, duration: 600.ms),

                      const SizedBox(height: 10),

                      Text(
                        'Sign in to continue your journey of helping',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ).animate(controller: _animationController)
                        .fadeIn(delay: 500.ms, duration: 600.ms)
                        .moveY(begin: 30, end: 0, duration: 600.ms),

                      const SizedBox(height: 40),

                      // Login Form with enhanced styling
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDark 
                                ? Colors.black.withOpacity(0.3) 
                                : Colors.grey.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: isDark 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              _buildAnimatedTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                                delay: 700.ms,
                              ),

                              const SizedBox(height: 20),

                              // Password Field
                              _buildAnimatedTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: theme.primaryColor.withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    setState(
                                        () => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                enabled: !_isLoading,
                                delay: 900.ms,
                              ),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : _forgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 0),
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(controller: _animationController)
                        .fadeIn(delay: 600.ms, duration: 800.ms)
                        .moveY(begin: 30, end: 0, duration: 800.ms),

                      const SizedBox(height: 30),

                      // Login Button with improved styling
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                            shadowColor: theme.primaryColor.withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ).animate(controller: _animationController)
                        .fadeIn(delay: 1100.ms, duration: 600.ms)
                        .moveY(begin: 30, end: 0, duration: 600.ms),

                      const SizedBox(height: 20),

                      // Error Message with enhanced styling
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.error.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 30),

                      // Sign Up Link with enhanced styling
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account?',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _goToRegister,
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(controller: _animationController)
                        .fadeIn(delay: 1400.ms, duration: 600.ms),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create floating community elements
  List<Widget> _buildFloatingElements(Color primaryColor, bool isDark) {
    return [
      Positioned(
        top: 20,
        right: 110,
        child: _buildFloatingIcon(
          Icons.favorite,
          Colors.redAccent,
          isDark,
          delay: 200.ms,
        ),
      ),
      Positioned(
        bottom: 20,
        left: 110,
        child: _buildFloatingIcon(
          Icons.handshake,
          Colors.orangeAccent,
          isDark,
          delay: 300.ms,
        ),
      ),
      Positioned(
        top: 60,
        left: 100,
        child: _buildFloatingIcon(
          Icons.health_and_safety,
          Colors.greenAccent,
          isDark,
          delay: 400.ms,
        ),
      ),
    ];
  }

  // Helper method to create a floating community icon
  Widget _buildFloatingIcon(IconData icon, Color color, bool isDark, {required Duration delay}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    ).animate(controller: _animationController)
      .fadeIn(delay: delay, duration: 600.ms)
      .moveY(begin: 20, end: 0, duration: 800.ms, curve: Curves.elasticOut);
  }

  // Method removed as social login buttons are no longer needed

  // Custom animated text field with enhanced styling
  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
    Duration delay = Duration.zero,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.primaryColor.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon, 
          color: theme.primaryColor.withOpacity(0.7),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
      ),
      validator: validator,
      enabled: enabled,
    ).animate(controller: _animationController)
      .fadeIn(delay: delay, duration: 600.ms)
      .moveY(begin: 30, end: 0, duration: 600.ms);
  }
}

// Custom painter to create subtle background pattern
class BackgroundPatternPainter extends CustomPainter {
  final Color primaryColor;
  final bool isDarkMode;

  BackgroundPatternPainter({
    required this.primaryColor,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(isDarkMode ? 0.05 : 0.03)
      ..style = PaintingStyle.fill;

    // Draw top-right decorative shape
    final path1 = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.65, 0)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.15, size.width, size.height * 0.25)
      ..close();
    canvas.drawPath(path1, paint);

    // Draw bottom-left decorative shape
    final path2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.35, size.height)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.85, 0, size.height * 0.7)
      ..close();
    canvas.drawPath(path2, paint);

    // Draw small circles representing community/connection
    final circlePaint = Paint()
      ..color = primaryColor.withOpacity(isDarkMode ? 0.08 : 0.05)
      ..style = PaintingStyle.fill;

    // Create a grid of small circles
    final double spacing = size.width / 15;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        // Add some randomness to positions
        if ((x + y) % 40 == 0) {
          canvas.drawCircle(
            Offset(x, y),
            3,
            circlePaint,
          );
        }
      }
    }

    // Add a few connection lines
    final linePaint = Paint()
      ..color = primaryColor.withOpacity(isDarkMode ? 0.04 : 0.02)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      double startX = size.width * (i % 2 == 0 ? 0.2 : 0.8);
      double startY = size.height * ((i % 4) / 4.0);
      double endX = size.width * ((i % 3) / 3.0);
      double endY = size.height * (i % 2 == 0 ? 0.7 : 0.3);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}