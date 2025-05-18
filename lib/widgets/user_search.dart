import 'package:flutter/material.dart';
import 'package:madadgar/models/user.dart';
import 'package:madadgar/services/user_service.dart';
import 'package:madadgar/screens/profile/user_profile_screen.dart';
import 'package:madadgar/config/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSearchWidget extends StatefulWidget {
  const UserSearchWidget({Key? key}) : super(key: key);

  @override
  State<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends State<UserSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final results = await _userService.searchUsersByName(query);
      
      // Filter out the current user from search results
      final filteredResults = results.where((user) => user.id != _currentUserId).toList();
      
      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      // You might want to show an error message here
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: TextStyle(
                fontFamily: fontFamily,
                color: Colors.grey[500],
              ),
              prefixIcon: Icon(Icons.search, color: primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: primaryColor),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _showResults = false;
                        });
                      },
                    )
                  : null,
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
            ),
            onChanged: (value) {
              // Debounce search to avoid too many Firebase calls
              Future.delayed(const Duration(milliseconds: 500), () {
                if (value == _searchController.text) {
                  _searchUsers(value);
                }
              });
            },
          ),
        ),
        if (_showResults)
          Expanded(
            child: _isSearching
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: user.profileImage.isEmpty
                                      ? primaryColor.withOpacity(0.1)
                                      : null,
                                  image: user.profileImage.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(user.profileImage),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: user.profileImage.isEmpty
                                    ? Center(
                                        child: Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                                          style: TextStyle(
                                            fontSize: 24,
                                            color: primaryColor,
                                            fontFamily: fontFamily,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (user.isVerified) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.verified, size: 16, color: Colors.blue),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.region,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildStatBadge(
                                        Icons.volunteer_activism,
                                        "${user.helpCount}",
                                        "helped",
                                        Colors.green[700]!,
                                        fontFamily,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatBadge(
                                        Icons.favorite,
                                        "${user.thankCount}",
                                        "thanks",
                                        Colors.red[400]!,
                                        fontFamily,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileScreen(userId: user.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
      ],
    );
  }
  
  Widget _buildStatBadge(IconData icon, String count, String label, Color color, String fontFamily) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            "$count $label",
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}