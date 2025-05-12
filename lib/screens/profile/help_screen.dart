import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:madadgar/config/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedSectionIndex;

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
            'Help & Support',
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
                SizedBox(height: 20),
                _buildSections(fontFamily, primaryColor),
                _buildContactSupport(fontFamily, primaryColor),
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
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  Color.lerp(primaryColor, Colors.black, 0.1)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
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
                Icons.help_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'How can we help you?',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Find answers to common questions and learn how to make the most of Madadgar',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSections(String fontFamily, Color primaryColor) {
    final sections = [
      {
        'title': 'General Overview',
        'icon': Icons.info_outline,
        'questions': [
          {
            'question': 'What is Madadgar?',
            'answer': 'Madadgar is a community-driven platform designed to connect people in need with those who are willing to offer help. Our mission is to facilitate resource sharing, mutual aid, and community support in a dignified and accessible way.\n\nThe app allows users to post requests for assistance or offers to help across various categories including food, education, healthcare, and more. By eliminating middlemen and bureaucracy, we create direct connections between community members.',
          },
          {
            'question': 'How to use Madadgar',
            'answer': 'Using Madadgar is simple and intuitive:\n\n1. Create an account using your email or phone number\n2. Browse the feed to see needs and offers in your community\n3. Post your own needs or offers using the "+" button\n4. Connect with others through the in-app messaging system\n5. Mark requests as fulfilled once help has been received\n\nThe app is designed to be accessible to everyone, regardless of technical expertise. The home screen shows you posts from your local community by default.',
          },
        ],
      },
      {
        'title': 'Account & Profile',
        'icon': Icons.person_outline,
        'questions': [
          {
            'question': 'How to create an account',
            'answer': 'To create a new Madadgar account:\n\n1. Launch the app and tap "Don\'t have an account? Sign up"\n2. Enter your full name as you\'d like it to appear\n3. Provide a valid email address (for account recovery)\n4. Enter your phone number (for verification)\n5. Create a strong password (at least 8 characters)\n6. Verify your phone number via SMS code\n7. Complete your profile by adding a profile picture (optional)\n8. Choose your location settings to see relevant local posts\n\nWe recommend using a real name and photo to build trust, but you can still post anonymously later if needed.',
          },
          {
            'question': 'How to log in/out',
            'answer': 'To log in:\n1. Open the Madadgar app\n2. Enter your registered email or phone number\n3. Enter your password\n4. Tap "Log In"\n5. Enable biometric login if prompted (recommended for security)\n\nTo log out:\n1. Open the side menu by tapping the hamburger icon\n2. Scroll down to find "Log Out"\n3. Confirm that you want to log out\n\nAlternatively, you can log out through Settings → Account → Log Out.',
          },
          {
            'question': 'Resetting your password',
            'answer': 'If you\'ve forgotten your password:\n\n1. On the login screen, tap "Forgot Password?"\n2. Enter the email address associated with your account\n3. Check your email for a password reset link (check spam folder too)\n4. Tap the link and follow instructions to create a new password\n5. Log in with your new password\n\nIf you know your current password but want to change it:\n1. Go to Settings → Security → Change Password\n2. Enter your current password\n3. Enter and confirm your new password\n4. Tap "Save Changes"\n\nFor security reasons, password reset links expire after 24 hours.',
          },
          {
            'question': 'Updating profile information',
            'answer': 'To update your profile:\n\n1. Go to the side menu and tap your profile picture or name\n2. Alternatively, go to Settings → Profile\n3. Tap "Edit Profile" to make changes\n4. You can update your:\n   - Profile picture (tap the current picture)\n   - Display name\n   - Bio/About Me section\n   - Contact preferences\n   - Location settings\n5. Tap "Save" when you\'re done\n\nYour email address cannot be changed once verified. If you need to change your primary email, please contact support.',
          },
          {
            'question': 'Deleting or updating posts',
            'answer': 'To manage your posts:\n\n1. Go to My Posts through the side menu or Settings\n2. You\'ll see all your active posts divided into "My Needs" and "My Offers"\n\nTo update a post:\n1. Tap on the post you want to edit\n2. Tap the pencil icon in the top right\n3. Make your changes to title, description, category, or location\n4. Tap "Update Post" to save changes\n\nTo delete a post:\n1. Find the post in your list\n2. Swipe left on the post or tap the three dots menu\n3. Select "Delete"\n4. Confirm deletion when prompted\n\nNote: Once a post is deleted, it cannot be recovered. If a post has active conversations, consider marking it as "Fulfilled" instead of deleting it.',
          },
          {
            'question': 'Responding to users',
            'answer': 'When you find a post you\'d like to respond to:\n\n1. Open the post details by tapping on it\n2. Tap the "Respond" button at the bottom\n3. This will open a chat window with the post owner\n4. Introduce yourself and explain how you can help or why you\'re reaching out\n5. Wait for the other user to reply\n\nTips for effective communication:\n- Be clear about what you can offer or need\n- Respond promptly to messages\n- Be respectful and understanding\n- Suggest a safe public place for meeting if exchanging items\n- Use the in-app chat for all communications for safety\n\nYou can access all your active conversations through the Messages tab.',
          },
        ],
      },
      {
        'title': 'Using the App',
        'icon': Icons.smartphone_outlined,
        'questions': [
          {
            'question': 'How to request help',
            'answer': 'To post a request for help:\n\n1. Tap the "+" button at the bottom of the screen\n2. Select "I Need Help"\n3. Choose the appropriate category for your need\n4. Add a clear, descriptive title (e.g., "Need math textbooks for 9th grade")\n5. Write a detailed description explaining your situation\n6. Add photos if relevant (optional but recommended)\n7. Set your location preference (neighborhood level for privacy)\n8. Choose whether to post anonymously\n9. Review your post and tap "Submit"\n\nYour post will appear in the feed for others in your community to see. Be specific about what you need to increase chances of getting appropriate help.',
          },
          {
            'question': 'How to offer help',
            'answer': 'To offer help to your community:\n\n1. Tap the "+" button at the bottom of the screen\n2. Select "I Can Offer Help"\n3. Choose the relevant category for your offer\n4. Create a descriptive title (e.g., "Offering free math tutoring")\n5. Write a detailed description of what you\'re offering\n   - Include any conditions or limitations\n   - Mention time availability if applicable\n6. Add photos of items if relevant\n7. Set your location preference\n8. Choose whether to post anonymously\n9. Review and tap "Submit"\n\nOffering specific items or services works better than general offers. Consider your safety and capacity before making commitments.',
          },
          {
            'question': 'Posting rules & community guidelines',
            'answer': 'Madadgar\'s Community Guidelines:\n\n• Respect & Dignity: Treat all users with respect regardless of background.\n\n• Honesty: Be truthful about your needs and offers.\n\n• No Exploitation: Don\'t take advantage of vulnerable community members.\n\n• No Illegal Content: No posts related to illegal activities, substances, or items.\n\n• No Hate Speech: No discrimination, threats, or harassment.\n\n• No Commercial Activity: Madadgar is not for business promotion or selling services.\n\n• Privacy Protection: Don\'t share others\' personal information without consent.\n\n• Appropriate Content: No adult content, graphic violence, or disturbing material.\n\n• Avoid Duplicates: Don\'t create multiple similar posts.\n\n• Safety First: Prioritize personal safety in all interactions.\n\nViolating these guidelines may result in content removal or account suspension.',
          },
          {
            'question': 'Finding posts relevant to you',
            'answer': 'To find posts that are most relevant to you:\n\n1. Use the search bar at the top of the feed\n2. Apply filters by tapping the filter icon:\n   - Filter by category (food, education, etc.)\n   - Filter by post type (needs or offers)\n   - Filter by distance from your location\n   - Filter by date posted\n3. Use the map view to see posts in specific areas\n4. Save searches for quick access later\n5. Set up notifications for specific categories\n\nThe feed automatically shows posts from your local area, with the most recent appearing first. Pull down to refresh the feed for new posts.',
          },
        ],
      },
      {
        'title': 'Safety & Privacy',
        'icon': Icons.shield_outlined,
        'questions': [
          {
            'question': 'Is my information secure?',
            'answer': 'Yes, your information security is our priority. Madadgar implements multiple layers of protection:\n\n• Data Encryption: All personal data and messages are encrypted in transit and at rest\n\n• Secure Authentication: We use industry-standard authentication protocols\n\n• Location Privacy: Your exact location is never shared, only neighborhood-level information\n\n• Anonymous Posting: Option to post without revealing your identity\n\n• Limited Data Collection: We only collect information necessary for the app\'s functionality\n\n• Regular Security Audits: Our systems undergo regular security assessments\n\n• Firebase Security: We use Google Firebase\'s enterprise-grade security infrastructure\n\nWe comply with relevant data protection regulations and never sell your personal information to third parties.',
          },
          {
            'question': 'How do you protect my data?',
            'answer': 'We take comprehensive measures to protect your data:\n\n• Technical Protection:\n  - End-to-end encryption for messages\n  - Secure HTTPS connections\n  - Data stored on secure Firebase servers\n  - Protection against common cyber threats\n  - Regular security updates\n\n• Access Controls:\n  - Strict internal access policies\n  - Authentication required for accessing any user data\n  - Regular access reviews\n\n• Data Minimization:\n  - We only collect data necessary for functionality\n  - Options to limit what you share\n\n• Retention Policies:\n  - Clear policies on how long data is kept\n  - Options to delete your data\n\nOur complete Privacy Policy is available in the app under Settings → Privacy Policy.',
          },
          {
            'question': 'Blocking/reporting users',
            'answer': 'If you encounter inappropriate behavior:\n\n1. To block a user:\n   - Go to their profile or open your chat with them\n   - Tap the three dots menu in the top right\n   - Select "Block User"\n   - Confirm your choice\n   - Blocked users cannot see your posts or message you\n\n2. To report a user:\n   - Go to their profile or the problematic content\n   - Tap the three dots menu\n   - Select "Report"\n   - Choose the reason for reporting\n   - Add additional details if needed\n   - Submit the report\n\nOur moderation team reviews all reports within 24 hours. You can manage your blocked list in Settings → Privacy → Blocked Users.',
          },
          {
            'question': 'What to do if you feel unsafe',
            'answer': 'Your safety is paramount. If you ever feel unsafe:\n\n1. Trust your instincts and remove yourself from any uncomfortable situation\n\n2. Immediately end communications with anyone making you uncomfortable\n\n3. Use the block function to prevent further contact\n\n4. Report the user through the app for our team to investigate\n\n5. If you feel physically threatened or in danger, contact local emergency services immediately\n\n6. Document any concerning messages or behaviors\n\n7. Contact our support team at 233539@students.au.edu.pk for guidance\n\nSafety Tips:\n• Always meet in public places for exchanges\n• Consider bringing a friend when meeting someone\n• Share your location with a trusted friend when meeting\n• Keep all communications within the app for documentation\n• Never share financial information or send money to other users',
          },
        ],
      },
      {
        'title': 'Frequently Asked Questions',
        'icon': Icons.question_answer_outlined,
        'questions': [
          {
            'question': 'Can I delete a post?',
            'answer': 'Yes, you can delete any post you\'ve created at any time. Go to "My Posts" in the menu or settings, find the post you want to remove, and tap the delete icon or use the three-dot menu to select "Delete."\n\nIf your need has been fulfilled or your offer is no longer available, consider marking the post as "Fulfilled" instead of deleting it. This helps maintain a record of community support and contributes to your profile\'s help history.\n\nNote that once a post is deleted, all associated messages will also become inaccessible. If you\'re in active communication with someone about the post, consider informing them before deletion.',
          },
          {
            'question': 'How do I know a helper is trustworthy?',
            'answer': 'Assessing trustworthiness is important for safe interactions. Consider these factors:\n\n• Profile Completion: Users with complete profiles (photo, bio, verified contact) tend to be more reliable\n\n• Reputation System: Check their "Thanks Received" and "Help Given" counts\n\n• Member Since: Longer-term members have established history\n\n• Previous Activity: View their public post history\n\n• Communications: Trust your instincts during chats - clear, respectful communication is a good sign\n\n• Reviews: Check if they have reviews from other users\n\nTips for safety:\n- Chat through the app before meeting\n- Meet in public places during daylight hours\n- Tell someone where you\'re going\n- Trust your instincts - if something feels wrong, don\'t proceed',
          },
          {
            'question': 'How long do posts stay visible?',
            'answer': 'Posts on Madadgar remain visible until one of the following occurs:\n\n1. You manually delete the post\n2. You mark the post as "Fulfilled"\n3. The post reaches the automatic expiration time (30 days by default)\n\nYou can adjust the expiration time when creating a post (options range from 1 day to 90 days). After expiration, posts are automatically archived but remain visible on your profile as "Past Posts."\n\nTo extend a post\'s visibility before it expires:\n1. Go to "My Posts"\n2. Find the post you want to extend\n3. Tap the three dots menu\n4. Select "Extend Duration"\n5. Choose a new expiration timeline\n\nRegularly updating your post status helps keep the community feed relevant and current.',
          },
          {
            'question': 'Can I post anonymously?',
            'answer': 'Yes, Madadgar offers anonymous posting options for users who prefer privacy. When creating a post, you\'ll see an "Post Anonymously" toggle option.\n\nWhen posting anonymously:\n• Your name and profile picture won\'t be visible on the public post\n• The post will show as "Anonymous User"\n• Your general location area will still appear (but not exact location)\n• Once someone responds, you can choose whether to reveal your identity\n\nThis feature is especially helpful for:\n- Those requesting sensitive help (financial, medical, etc.)\n- Users concerned about stigma\n- Those new to the community\n\nEven when posting anonymously, our community guidelines still apply, and moderators can identify users if posts violate our policies.',
          },
          {
            'question': 'Can I edit a post after publishing?',
            'answer': 'Yes, you can edit your posts after publishing to add information, fix errors, or update availability. To edit a post:\n\n1. Go to "My Posts" in the menu\n2. Find the post you want to modify\n3. Tap on it to open the details view\n4. Tap the pencil icon in the top right\n5. Make your changes to any field\n6. Tap "Update Post" to save\n\nEditable elements include:\n• Title and description\n• Category\n• Photos (add, remove, or change)\n• Location radius\n• Duration/expiration date\n\nAll edits are timestamped, and substantial changes will show an "Edited" indicator on the post. Consider adding a note in the description explaining significant changes to maintain transparency with users who may have seen the original version.',
          },
        ],
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final isExpanded = _expandedSectionIndex == index;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // Section Header
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedSectionIndex = isExpanded ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              section['icon'] as IconData,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              section['title'] as String,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Questions List
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: isExpanded ? null : 0,
                    child: isExpanded
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: (section['questions'] as List).length,
                            itemBuilder: (context, qIndex) {
                              final question = (section['questions'] as List)[qIndex];
                              return _buildQuestion(
                                question: question['question'] as String,
                                answer: question['answer'] as String,
                                fontFamily: fontFamily,
                                primaryColor: primaryColor,
                              );
                            },
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestion({
    required String question,
    required String answer,
    required String fontFamily,
    required Color primaryColor,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        question,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: primaryColor,
      collapsedIconColor: Colors.grey[500],
      childrenPadding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryColor.withOpacity(0.1)),
          ),
          padding: EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupport(String fontFamily, Color primaryColor) {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.85),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.support_agent,
              size: 32,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Still Need Help?',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Our support team is ready to assist you with any questions or issues not covered in this guide.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildContactMethod(
                icon: Icons.email_outlined,
                title: 'Email Support',
                onTap: () => _launchUrl('mailto:233539@students.au.edu.pk'),
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              _buildContactMethod(
                icon: Icons.chat_outlined,
                title: 'Live Chat',
                onTap: () {},
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              _buildContactMethod(
                icon: Icons.phone_outlined,
                title: 'Call Us',
                onTap: () => _launchUrl('tel:+923312137110'),
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
              _buildContactMethod(
                icon: Icons.forum_outlined,
                title: 'Forum',
                onTap: () {},
                fontFamily: fontFamily,
                primaryColor: primaryColor,
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Response Time: Within 24 hours',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required Function() onTap,
    required String fontFamily,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 130,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
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