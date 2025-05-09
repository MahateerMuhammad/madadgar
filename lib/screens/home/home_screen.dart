import 'package:flutter/material.dart';
import 'package:madadgar/screens/home/nearby_screen.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/config/constants.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/screens/home/feed_screen.dart';
import 'package:madadgar/screens/post/create_post_screen.dart';
import 'package:madadgar/screens/profile/profile_screen.dart';

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
    const Center(child: Text('Alerts coming soon...')),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Feed',
    'Nearby',
    'Alerts',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    final accentColor = HSLColor.fromColor(primaryColor).withLightness(0.85).toColor();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
     appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor), // Makes drawer/menu icon primary
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
        // Navigate to chat screen or show dialog
        // Example: Navigator.pushNamed(context, '/chat');
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Nearby'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(String fontFamily, Color primaryColor, Color accentColor) {
    final user = Provider.of<AuthService>(context).currentUser;
    
    return Drawer(
    child: Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            color: primaryColor,
          ),
          accountName: Text(
            user?.name ?? 'User Name',
            style: TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          accountEmail: Text(
            user?.email ?? 'user@example.com',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
            ),
          ),
          currentAccountPicture: CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: user?.profileImage != null && user!.profileImage!.isNotEmpty
              ? NetworkImage(user.profileImage!)
              : null,
          child: (user?.profileImage == null || user!.profileImage!.isEmpty)
              ? Icon(
                  Icons.person,
                  size: 40,
                  color: primaryColor,
                )
      : null,
),
        ),
         
          const Divider(),
          ListTile(
            leading: Icon(Icons.post_add, color: primaryColor),
            title: Text(
              'Create New Post',
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreatePostScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.grey[700]),
            title: Text(
              'Settings',
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.grey[700]),
            title: Text(
              'Help & Support',
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey[700]),
            title: Text(
              'About',
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout', 
              style: TextStyle(
                color: Colors.red,
                fontFamily: fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
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