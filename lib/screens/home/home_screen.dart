import 'package:flutter/material.dart';
import 'package:madadgar/screens/home/nearby_screen.dart';
import 'package:madadgar/screens/profile/help_screen.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/config/constants.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/screens/home/feed_screen.dart';
import 'package:madadgar/screens/post/create_post_screen.dart';
import 'package:madadgar/screens/profile/profile_screen.dart';
import 'package:madadgar/screens/chat/conversation_list.dart';
import 'package:madadgar/screens/home/about.dart';
import 'package:madadgar/screens/profile/settings_screen.dart';
import 'package:madadgar/screens/post/my_posts_screen.dart';
import 'package:madadgar/screens/education/education_resource_screen.dart';
import 'package:madadgar/screens/education/upload_resource_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    FeedScreen(),
    NearbyScreen(),
    EducationalResourcesScreen (),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Feed',
    'Nearby',
    'Resources',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    final accentColor =
        HSLColor.fromColor(primaryColor).withLightness(0.85).toColor();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
            color: primaryColor), // Makes drawer/menu icon primary
        centerTitle: _currentIndex != 0,
        title: _currentIndex == 0
            ? Row(
                children: [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              )
            : Text(
                _titles[_currentIndex],
                style: TextStyle(
                  fontFamily: fontFamily,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: primaryColor),
            onPressed: () {
              // Navigate to the ConversationsListScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ConversationsListScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      drawer: _buildNavigationDrawer(fontFamily, primaryColor, accentColor),
      body: _screens[_currentIndex],
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton(
              backgroundColor: primaryColor,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreatePostScreen()),
                );
              },
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Feed'),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Nearby'),
          BottomNavigationBarItem(
              icon: Icon(Icons.cast_for_education_outlined),
              activeIcon: Icon(Icons.cast_for_education),
              label: 'Education'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(
      String fontFamily, Color primaryColor, Color accentColor) {
    final user = Provider.of<AuthService>(context).currentUser;

    return Drawer(
      child: Container(
        color: Colors.grey[50], // Using light background from app theme
        child: Column(
          children: [
            // User info header
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              decoration: BoxDecoration(
                color: primaryColor, // Using primary color from app theme
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image with white border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        backgroundImage: user?.profileImage != null &&
                                user!.profileImage!.isNotEmpty
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child: (user?.profileImage == null ||
                                user!.profileImage!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 36,
                                color: primaryColor,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // User name
                    Text(
                      user?.name ?? 'User Name',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // User region/bio (optional)
                    //         if (user?.bio != null && user!.bio!.isNotEmpty)
                    //           Text(
                    //             user.bio!,
                    //             style: TextStyle(
                    //               fontFamily: fontFamily,
                    //               color: Colors.white.withOpacity(0.9),
                    //               fontSize: 13,
                    //               fontWeight: FontWeight.w400,
                    //             ),
                    //             maxLines: 1,
                    //             overflow: TextOverflow.ellipsis,
                    //           ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Main navigation section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'MAIN NAVIGATION',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Main navigation items
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Home / Feed',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 0);
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.article,
                      title: 'My Posts',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MyPostsScreen()),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.add_circle,
                      title: 'Create Post',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CreatePostScreen()),
                        );
                      },
                    ),

                       _buildDrawerItem(
                      icon: Icons.cast_for_education,
                      title: 'Educational Resources',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EducationalResourcesScreen()),
                        );
                      },
                      ),

                      _buildDrawerItem(
                      icon: Icons.add_circle,
                      title: 'Create Educational Resource',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UploadResourceScreen()),
                        );
                      },
                    ),

                    Divider(
                        color: Colors.grey.withOpacity(0.3),
                        indent: 16,
                        endIndent: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'OTHER LINKS',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Profile',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                     onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HelpScreen()),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.info,
                      title: 'About Madadgar',
                      primaryColor: primaryColor,
                      fontFamily: fontFamily,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AboutScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer with logout button
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Divider(color: Colors.grey.withOpacity(0.3)),
                  ListTile(
                    leading: Icon(Icons.logout, color: primaryColor),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      await authService.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper method to create drawer items with consistent styling
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color primaryColor,
    required String fontFamily,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontFamily: fontFamily,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      dense: true,
      onTap: onTap,
    );
  }

  void _showSearchDialog() {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Search',
          style: TextStyle(
            fontFamily: fontFamily,
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          style: TextStyle(fontFamily: fontFamily),
          decoration: InputDecoration(
            hintText: 'Search for needs or offers...',
            hintStyle: TextStyle(fontFamily: fontFamily),
            prefixIcon: Icon(Icons.search, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            // Handle search or navigate to search results screen
          },
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.grey[700],
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2,
            ),
            child: Text(
              'Search',
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Handle search or navigate to search results screen
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.volunteer_activism, color: primaryColor),
            SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontFamily: fontFamily,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '${AppConstants.appName} is a platform connecting people who need help with volunteers willing to provide assistance.',
              style: TextStyle(
                fontFamily: fontFamily,
                height: 1.4,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: fontFamily,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
