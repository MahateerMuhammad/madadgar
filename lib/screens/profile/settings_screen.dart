import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/screens/auth/login_screen.dart';
import 'package:madadgar/screens/post/my_posts_screen.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/config/routes.dart';
import 'package:madadgar/services/user_service.dart';
import 'package:madadgar/screens/home/about.dart';
import 'package:madadgar/screens/auth/forgot_screen_password.dart';
import 'package:madadgar/screens/verification/verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(builder: (_) => const SettingsScreen());
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  final bool _isDeleting = false;
  final String _appVersion = "1.0.0";

  void _logout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password reset email sent. Please check your inbox."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone, and all your data will be permanently deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Final Confirmation"),
        content: const Text(
          "Please type 'DELETE' to confirm you want to permanently delete your account and all associated data.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteAccount();
            },
            child: const Text(
              "Confirm Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _performDeleteAccount() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user posts
        // TODO: Implement post deletion service
        
        // Delete user data from Firestore
        await _userService.deleteUser(user.uid);
        
        // Delete user account from Firebase Auth
        await user.delete();
        
        // Navigate to login screen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting account: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLegalDocument(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showTermsOfUse() {
    _showLegalDocument(
      "Terms of Use",
      "These are the Terms of Use for Madadgar App. By using this application, you agree to these terms.\n\n"
      "1. You must be at least 18 years old to use this service.\n"
      "2. You are responsible for any content you post.\n"
      "3. Harmful, illegal, or inappropriate content is not allowed.\n"
      "4. We reserve the right to terminate accounts that violate these terms.\n\n"
      "These terms may be updated from time to time, and your continued use of the service constitutes acceptance of any changes."
    );
  }

  void _showPrivacyPolicy() {
    _showLegalDocument(
      "Privacy Policy",
      "Privacy Policy for Madadgar App\n\n"
      "Information We Collect:\n"
      "• Personal information you provide (name, email, location)\n"
      "• Content you post\n"
      "• Usage data and interaction with the app\n\n"
      "How We Use Information:\n"
      "• To provide and improve our services\n"
      "• To communicate with you\n"
      "• To ensure safety and security of our platform\n\n"
      "Data Sharing:\n"
      "We don't sell your personal information. We may share data with service providers who help us deliver our services."
    );
  }

  void _submitFeedback() {
    // Show a dialog with a feedback form
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Feedback"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Help us improve Madadgar by sharing your feedback:"),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Type your feedback here...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Send feedback (implement this)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Thank you for your feedback!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              "Submit",
              style: TextStyle(color: MadadgarTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMyPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyPostsScreen()),
    );
  }

  void _navigateToEditProfile() {
    // TODO: Implement edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit profile coming soon")),
    );
  }

  void _navigateToVerify(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerificationScreen()),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("About Madadgar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MadadgarTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.healing,
                size: 50,
                color: MadadgarTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Madadgar",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Version $_appVersion",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              "Madadgar is an app designed to help people connect and support each other in times of need.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "© 2025 Madadgar Team",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              "Contact: support@madadgar.com",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Settings",
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
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            children: [
              // Account Section
              _buildSectionTitle("Account", Icons.person_outline),
              _buildSettingCard(
                title: "Edit Profile",
                subtitle: "Change your name, email, and location",
                icon: Icons.edit_outlined,
                iconColor: primaryColor,
                onTap: _navigateToEditProfile,
              ),
               _buildSettingCard(
                title: "Verify Yourself",
                subtitle: "Verify your identity for better trust",
                icon: Icons.verified_user_outlined,
                iconColor: Colors.green[700]!,
                onTap: _navigateToVerify,
              ),
              _buildSettingCard(
                title: "Change Password",
                subtitle: "Reset your account password",
                icon: Icons.lock_outline,
                iconColor: Colors.blue[700]!,
               onTap: () {
                       
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>const ForgetPasswordScreen()),
                        );
                      },
              ),
              _buildSettingCard(
                title: "My Posts",
                subtitle: "View and manage your posts",
                icon: Icons.article_outlined,
                iconColor: Colors.green[700]!,
                onTap: _navigateToMyPosts,
              ),
              
              const SizedBox(height: 24),
              
              // Support & Feedback Section
              _buildSectionTitle("Support & Feedback", Icons.support_agent),
              _buildSettingCard(
                title: "Help Center",
                subtitle: "FAQs and user guides",
                icon: Icons.help_outline,
                iconColor: Colors.amber[700]!,
                onTap: () {},
              ),
              _buildSettingCard(
                title: "Send Feedback",
                subtitle: "Report issues or suggest improvements",
                icon: Icons.feedback_outlined,
                iconColor: Colors.purple[700]!,
                onTap: _submitFeedback,
              ),
              _buildSettingCard(
                title: "About Madadgar",
                subtitle: "Version info and app details",
                icon: Icons.info_outline,
                iconColor: Colors.teal[700]!,
                onTap: () {
                       
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>const AboutScreen()),
                        );
                      },
              ),
              
              const SizedBox(height: 24),
              
              // Legal Section
              _buildSectionTitle("Legal", Icons.gavel_outlined),
              _buildSettingCard(
                title: "Terms of Use",
                subtitle: "Rules for using Madadgar",
                icon: Icons.description_outlined,
                iconColor: Colors.indigo[700]!,
                onTap: _showTermsOfUse,
              ),
              _buildSettingCard(
                title: "Privacy Policy",
                subtitle: "How we handle your data",
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.blue[800]!,
                onTap: _showPrivacyPolicy,
              ),
              
              const SizedBox(height: 24),
              
              // Danger Zone Section
              _buildSectionTitle("Danger Zone", Icons.warning_amber_rounded, color: Colors.red),
              _buildSettingCard(
                title: "Delete Account",
                subtitle: "Permanently remove your account and all data",
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: _deleteAccount,
              ),
              
              const SizedBox(height: 24),
              
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Logout",
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 18, 
            color: color ?? Colors.black87,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: MadadgarTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: MadadgarTheme.fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: MadadgarTheme.fontFamily,
            fontSize: 13,
            color: textColor != null ? textColor.withOpacity(0.7) : Colors.black54,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}