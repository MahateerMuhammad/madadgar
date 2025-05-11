import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:madadgar/config/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    final accentColor = HSLColor.fromColor(primaryColor).withLightness(0.85).toColor();
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'About Madadgar',
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(accentColor, primaryColor, fontFamily),
                _buildMissionSection(fontFamily, primaryColor),
                _buildHowItWorksSection(fontFamily, primaryColor),
                _buildTeamSection(fontFamily, primaryColor),
                _buildContactSection(fontFamily, primaryColor),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor, Color primaryColor, String fontFamily) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  Color.lerp(primaryColor, Colors.black, 0.1)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.volunteer_activism,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Madadgar',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Community Aid & Resource Sharing Platform',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Text(
              'Connecting those in need with those willing to give',
              style: TextStyle(
                fontFamily: fontFamily,
                color: primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String fontFamily) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 4,
            decoration: BoxDecoration(
              color: MadadgarTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(String fontFamily, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Our Mission', fontFamily),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Madadgar aims to create a direct connection between those who need help and those who can provide it, fostering a culture of community support and resource sharing.',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _buildMissionPoint(
                    icon: Icons.group_outlined,
                    title: 'Community',
                    description: 'Building stronger connections',
                    fontFamily: fontFamily,
                    primaryColor: primaryColor,
                  ),
                  SizedBox(width: 12),
                  _buildMissionPoint(
                    icon: Icons.handshake_outlined,
                    title: 'Support',
                    description: 'Direct help without barriers',
                    fontFamily: fontFamily,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildMissionPoint(
                    icon: Icons.security_outlined,
                    title: 'Dignity',
                    description: 'Preserving respect and privacy',
                    fontFamily: fontFamily,
                    primaryColor: primaryColor,
                  ),
                  SizedBox(width: 12),
                  _buildMissionPoint(
                    icon: Icons.school_outlined,
                    title: 'Education',
                    description: 'Sharing knowledge and resources',
                    fontFamily: fontFamily,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionPoint({
    required IconData icon,
    required String title,
    required String description,
    required String fontFamily,
    required Color primaryColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection(String fontFamily, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('How It Works', fontFamily),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStepItem(
                number: 1,
                title: 'Post a Need or Offer',
                description: 'Create a post describing what you need or what you can offer to others.',
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16),
              _buildStepItem(
                number: 2,
                title: 'Connect with Others',
                description: 'Browse posts from your community and connect with people nearby.',
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16),
              _buildStepItem(
                number: 3,
                title: 'Give Help or Thanks',
                description: 'Respond to posts and build community connections through mutual support.',
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16),
              _buildStepItem(
                number: 4,
                title: 'Build Community',
                description: 'Earn recognition for your contributions and help create a better society.',
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required int number,
    required String title,
    required String description,
    required String fontFamily,
    required Color primaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
Widget _buildTeamSection(String fontFamily, Color primaryColor) {
  // Define a common width factor to ensure all boxes have the same width
  final double boxWidth = 142.0;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('Our Team', fontFamily),
      Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Madadgar was developed by a team of passionate computer science students at AU University who believe in technology power to create positive social impact.',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            // First row with 2 team members - using fixed width constraints
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: boxWidth,
                  child: _buildTeamMember(
                    name: 'Mahateer M',
                    role: '233539@students.au.edu.pk',
                    github: 'https://github.com/MahateerMuhammad',
                    fontFamily: fontFamily,
                    primaryColor: primaryColor,
                  ),
                ),
                SizedBox(width: 20),
                Container(
                  width: boxWidth,
                  child: _buildTeamMember(
                    name: 'Arsal Ajmal',
                    role: '233503@students.au.edu.pk',
                    github: 'github',
                    fontFamily: fontFamily,
                    primaryColor: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Second row with 2 team members - using fixed width constraints
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: boxWidth,
                  child: _buildTeamMember(
                    name: 'Maham kamran',
                    role: '233798@students.au.edu.pk',
                    github: 'github',
                    fontFamily: fontFamily,
                    primaryColor: primaryColor,
                  ),
                ),
                SizedBox(width: 20),
                Container(
                  width: boxWidth,
                  child: _buildTeamMember(
                    name: 'Shah Abdullah',
                    role: '233585@students.au.edu.pk',
                    github: 'github',
                    fontFamily: fontFamily,
                    primaryColor: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Third row with 1 team member centered
            Center(
              child: Container(
                width: boxWidth,
                child: _buildTeamMember(
                  name: 'Fatima Faisal',
                  role: '233545@students.au.edu.pk',
                  github: 'github',
                  fontFamily: fontFamily,
                  primaryColor: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildTeamMember({
  required String name,
  required String role,
  required String github,
  required String fontFamily,
  required Color primaryColor,
}) {
  return InkWell(
    onTap: () => _launchUrl(github),
    child: Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: primaryColor.withOpacity(0.2),
            child: Icon(
              Icons.person_outline,
              color: primaryColor,
              size: 26,
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            role,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.code,
                size: 14,
                color: primaryColor,
              ),
              SizedBox(width: 4),
              Text(
                'GitHub',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 12,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  Widget _buildContactSection(String fontFamily, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contact Us', fontFamily),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildContactItem(
                icon: Icons.email_outlined,
                title: 'Email',
                value: '233539@students.au.edu.pk',
                onTap: () => _launchUrl('mailto:233539@students.au.edu.pk'),
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16),
              _buildContactItem(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: '+92 331 2137110',
                onTap: () => _launchUrl('tel:+923312137110'),
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16),
              _buildContactItem(
                icon: Icons.facebook_outlined,
                title: 'Facebook',
                value: 'Madadgar Community',
                onTap: () => _launchUrl('https://facebook.com'),
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 16),
              _buildContactItem(
                icon: Icons.photo_camera_outlined,
                title: 'Instagram',
                value: '@madadgar_community',
                onTap: () => _launchUrl('https://instagram.com'),
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Have suggestions or feedback?',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We\'d love to hear from you to improve Madadgar!',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _launchUrl('mailto:233539@students.au.edu.pk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Send Feedback',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required Function() onTap,
    required String fontFamily,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}