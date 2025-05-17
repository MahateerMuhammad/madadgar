import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:madadgar/models/education.dart';
import 'package:madadgar/services/edu_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/config/theme.dart';

class ResourceDetailScreen extends StatefulWidget {
  final EducationalResourceModel resource;

  const ResourceDetailScreen({
    Key? key,
    required this.resource,
  }) : super(key: key);

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final EducationalResourceService _resourceService = EducationalResourceService();
  final _auth = FirebaseAuth.instance;
  bool _isLiked = false;
  bool _isMine = false;
  bool _canLike = false;
  bool _canDownload = false;
  bool _isLoading = true;
  // Initialize directly instead of using late
  late EducationalResourceModel _resource = widget.resource;
  late int _likeCount = widget.resource.likeCount;
  
  @override
  void initState() {
    super.initState();
    _checkResourcePermissions();
  }
  
  // Check if the user owns the resource, can like it, and can download it
  Future<void> _checkResourcePermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Check if user owns the resource
        final isOwner = currentUser.uid == _resource.uploaderId;
        
        // User cannot like or download their own resources
        if (!isOwner) {
          // Check if user has already liked this resource
          final hasLiked = await _resourceService.hasUserLikedResource(_resource.id);
          
          setState(() {
            _isMine = isOwner;
            _isLiked = hasLiked;
            _canLike = !isOwner && !hasLiked;
            _canDownload = !isOwner;
          });
        } else {
          setState(() {
            _isMine = true;
            _canLike = false;
            _canDownload = false;
          });
        }
      }
    } catch (e) {
      print("Error checking resource permissions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking permissions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _downloadFile(BuildContext context, String url, String fileName) async {
    final dio = Dio();
    
    // Request storage permission
    var status = await Permission.storage.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required to download files')),
      );
      return;
    }
    
    // Create a download directory
    Directory? directory;
    if (Platform.isAndroid) {
      // Use the external storage directory on Android
      directory = Directory('/storage/emulated/0/Download');
      // Create if it doesn't exist
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      // Use the documents directory on iOS
      directory = await getApplicationDocumentsDirectory();
    }
    
    if (directory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access storage directory')),
      );
      return;
    }
    
    final savePath = '${directory.path}/$fileName';
    
    try {
      // Show download progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading file...')),
      );
      
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Update progress if needed
            print('${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File saved to: $savePath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              OpenFile.open(savePath);
            },
          ),
        ),
      );
    } catch (e) {
      print('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  Future<void> _downloadResource() async {
    if (!_canDownload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot download your own resource')),
      );
      return;
    }
    
    try {
      // Increment download count in Firestore
      await _resourceService.incrementDownloadCount(_resource.id);
      
      // Extract filename from URL
      String fileName = _resource.resourceUrl.split('/').last;
      
      // If filename doesn't have an extension, add one based on fileType
      if (!fileName.contains('.')) {
        String extension = _resource.fileType.toLowerCase();
        fileName = '$fileName.$extension';
      }
      
      // Download the file
      await _downloadFile(context, _resource.resourceUrl, fileName);
      
      // Update the UI to reflect the new download count
      setState(() {
        _resource = _resource.copyWith(downloadCount: _resource.downloadCount + 1);
      });
      
    } catch (e) {
      print("Error downloading resource: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
 Future<void> _toggleLike() async {
  if (_isMine) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot like your own resource')),
    );
    return;
  }
  
  if (_isLiked) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have already liked this resource')),
    );
    return;
  }
  
  // Update UI immediately for better user experience
  setState(() {
    _isLiked = true;
    _canLike = false;
    _likeCount += 1;
  });
  
  try {
    final success = await _resourceService.toggleLike(_resource.id, true);
    
    if (!success) {
      // If the backend operation fails, revert the UI changes
      setState(() {
        _isLiked = false;
        _canLike = true;
        _likeCount -= 1;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to like resource. Please try again.')),
      );
    } else {
      // Update the resource object to keep it in sync
      setState(() {
        _resource = _resource.copyWith(likeCount: _likeCount);
      });
      
      // Show success message but stay on the current screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource liked successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    // If there's an error, revert the UI changes
    setState(() {
      _isLiked = false;
      _canLike = true;
      _likeCount -= 1;
    });
    
    print("Error liking resource: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
  
  Future<void> _shareResource() async {
    await Share.share(
      'Check out this educational resource: ${_resource.title}\n${_resource.resourceUrl}',
      subject: _resource.title,
    );
  }
  
 Future<void> _deleteResource() async {
  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Resource'),
      content: const Text('Are you sure you want to delete this resource? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  ) ?? false;
  
  if (confirmed) {
    try {
      await _resourceService.deleteResource(_resource.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource deleted successfully')),
      );
      
      // Return with action=deleted to indicate resource was deleted
      Navigator.pop(context, {
        'action': 'deleted',
        'resourceId': _resource.id,
      });
    } catch (e) {
      print("Error deleting resource: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting resource: $e')),
      );
    }
  }
}

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 18, 
            color: Colors.black87,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: MadadgarTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
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
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontFamily: MadadgarTheme.fontFamily,
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        trailing: onTap != null ? Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      color: enabled ? Colors.white : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled ? iconColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled ? iconColor : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: MadadgarTheme.fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: MadadgarTheme.fontFamily,
            fontSize: 13,
            color: enabled ? Colors.black54 : Colors.grey[400],
          ),
        ),
        trailing: enabled ? Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ) : null,
        onTap: enabled ? onTap : null,
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  final fontFamily = MadadgarTheme.fontFamily;
  final primaryColor = MadadgarTheme.primaryColor;

  // ignore: deprecated_member_use
  return WillPopScope(
    onWillPop: () async {
      // Always return updated resource info when navigating back
      Navigator.pop(context, {
        'action': _isLiked ? 'liked' : null,
        'resourceId': _resource.id, 
        'updatedResource': _resource
      });
      return false; // Let our custom navigation handle it
    },
    child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Resource Details',
          style: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            color: MadadgarTheme.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MadadgarTheme.primaryColor),
          onPressed: () {
            // Return with updated resource when back button is pressed
            Navigator.pop(context, {
              'action': _isLiked ? 'liked' : null,
              'resourceId': _resource.id,
              'updatedResource': _resource
            });
          },
        ),
        actions: [
          if (_isMine)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteResource,
              tooltip: 'Delete Resource',
            ),
          IconButton(
            icon: const Icon(Icons.share, color: MadadgarTheme.primaryColor),
            onPressed: _shareResource,
            tooltip: 'Share Resource',
          ),
        ],
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
              // Resource image or type icon
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _resource.thumbnailUrl.isNotEmpty
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: _resource.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: Icon(Icons.error, size: 64, color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(
                              Icons.insert_drive_file,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Basic Information Section
              _buildSectionTitle("Basic Information", Icons.info_outline),
              _buildInfoCard(
                title: "Title",
                value: _resource.title,
                icon: Icons.title,
                iconColor: primaryColor,
              ),
              
              // Owner badge if it's the user's resource
              if (_isMine)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 0,
                  color: Colors.amber[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      "Your Resource",
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.amber[800],
                      ),
                    ),
                    subtitle: Text(
                      "You are the owner of this resource",
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 13,
                        color: Colors.amber[700],
                      ),
                    ),
                  ),
                ),
              
              if (_resource.isVerified)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 0,
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      "Verified Content",
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.blue[800],
                      ),
                    ),
                    subtitle: Text(
                      "This resource has been verified",
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ),
              
              _buildInfoCard(
                title: "Description",
                value: _resource.description,
                icon: Icons.description,
                iconColor: Colors.green[700]!,
              ),
              
              _buildInfoCard(
                title: "Category",
                value: _resource.category,
                icon: Icons.category,
                iconColor: Colors.purple[700]!,
              ),
              
              if (_resource.subCategory.isNotEmpty)
                _buildInfoCard(
                  title: "Sub Category",
                  value: _resource.subCategory,
                  icon: Icons.subdirectory_arrow_right,
                  iconColor: Colors.indigo[700]!,
                ),
              
              const SizedBox(height: 24),
              
              // Upload Information Section
              _buildSectionTitle("Upload Information", Icons.cloud_upload_outlined),
              _buildInfoCard(
                title: "Uploaded by",
                value: _resource.uploaderName,
                icon: Icons.person_outline,
                iconColor: Colors.teal[700]!,
              ),
              
              _buildInfoCard(
                title: "Upload Date",
                value: '${_resource.createdAt.day}/${_resource.createdAt.month}/${_resource.createdAt.year}',
                icon: Icons.calendar_today,
                iconColor: Colors.orange[700]!,
              ),
              
              const SizedBox(height: 24),
              
              // File Information Section
              _buildSectionTitle("File Information", Icons.insert_drive_file_outlined),
              _buildInfoCard(
                title: "File Type",
                value: _resource.fileType.toUpperCase(),
                icon: Icons.description,
                iconColor: Colors.red[700]!,
              ),
              
              const SizedBox(height: 24),
              
              // Statistics Section
              _buildSectionTitle("Statistics", Icons.analytics_outlined),
              _buildInfoCard(
                title: "Downloads",
                value: '${_resource.downloadCount}',
                icon: Icons.download,
                iconColor: Colors.blue[700]!,
              ),
              
              _buildInfoCard(
                title: "Likes",
                value: '$_likeCount',
                icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                iconColor: _isLiked ? Colors.green[700]! : Colors.grey[700]!,
              ),
              
              const SizedBox(height: 24),
              
              // Tags Section
              if (_resource.tags.isNotEmpty) ...[
                _buildSectionTitle("Tags", Icons.label_outline),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _resource.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Actions Section
              _buildSectionTitle("Actions", Icons.touch_app_outlined),
              
              // Show like button only if user can like
              if (_canLike || _isLiked)
                _buildActionCard(
                  title: _isLiked ? "Liked" : "Like Resource",
                  subtitle: _isLiked ? "You liked this resource" : "Show your appreciation",
                  icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  iconColor: _isLiked ? Colors.green[700]! : Colors.blue[700]!,
                  onTap: _toggleLike,
                  enabled: _canLike,
                ),
              
              // Show download button only if user can download
              if (_canDownload)
                _buildActionCard(
                  title: "Download Resource",
                  subtitle: "Download this file to your device",
                  icon: Icons.download,
                  iconColor: Colors.indigo[700]!,
                  onTap: _downloadResource,
                ),
              
              _buildActionCard(
                title: "Share Resource",
                subtitle: "Share this resource with others",
                icon: Icons.share,
                iconColor: Colors.orange[700]!,
                onTap: _shareResource,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
    ),
    );
  }
}