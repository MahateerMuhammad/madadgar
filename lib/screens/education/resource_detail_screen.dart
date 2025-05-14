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
      
      // Set the result to be returned to the previous screen
      // This will signal that the resource has been updated
      Navigator.pop(context, {
        'updated': true,
        'resourceId': _resource.id,
        'likeCount': _likeCount
      });
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
}// In ResourceDetailScreen.dart
// Split the like functionality from the navigation action
// Do not auto-navigate after liking




  @override
Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: Text(_resource.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
              icon: const Icon(Icons.delete),
              onPressed: _deleteResource,
              tooltip: 'Delete Resource',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResource,
            tooltip: 'Share Resource',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resource image or type icon
              if (_resource.thumbnailUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: _resource.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.insert_drive_file,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              
              // Resource details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with verification badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _resource.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_resource.isVerified)
                          const Tooltip(
                            message: 'Verified Content',
                            child: Icon(
                              Icons.verified,
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Owner badge if it's the user's resource
                    if (_isMine)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Your Resource',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Category and subcategory
                    Row(
                      children: [
                        Chip(
                          label: Text(_resource.category),
                          backgroundColor: Colors.blue[100],
                        ),
                        if (_resource.subCategory.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(_resource.subCategory),
                            backgroundColor: Colors.green[100],
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Uploader info and date
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Uploaded by ${_resource.uploaderName}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${_resource.createdAt.day}/${_resource.createdAt.month}/${_resource.createdAt.year}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_resource.description),
                    
                    const SizedBox(height: 24),
                    
                    // File information
                    const Text(
                      'File Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.insert_drive_file,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('File Type'),
                      subtitle: Text(_resource.fileType.toUpperCase()),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.download, color: Colors.blue),
                            const SizedBox(height: 4),
                            Text(
                              '${_resource.downloadCount}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text('Downloads'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              color: _isLiked ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_likeCount', // Use the local state variable
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text('Likes'),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tags
                    if (_resource.tags.isNotEmpty) ...[
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _resource.tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor: Colors.grey[200],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      bottomNavigationBar: _isLoading
        ? null
        : BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Like button with loading state
               TextButton.icon(
                onPressed: _canLike ? _toggleLike : null,
                icon: Icon(
                  _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: _isLiked 
                    ? Colors.blue 
                    : _canLike 
                      ? null 
                      : Colors.grey,
                ),
                label: Text(
                  _isLiked 
                    ? 'Liked' 
                    : _isMine 
                      ? 'Your Post'
                      : 'Like',
                  style: TextStyle(
                    color: _isLiked 
                      ? Colors.blue 
                      : _canLike 
                        ? null 
                        : Colors.grey,
                  ),
                ),
              ),

                
                // Share button
                TextButton.icon(
                  onPressed: _shareResource,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                
                // Download button (primary action)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: _canDownload ? _downloadResource : null,
                      icon: const Icon(Icons.download),
                      label: Text(_canDownload ? 'Download' : _isMine ? 'Your Post' : 'Cannot Download'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ),
    );
  }
}