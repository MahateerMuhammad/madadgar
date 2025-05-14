import 'package:flutter/material.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/models/education.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;


class ResourceFeedItem extends StatelessWidget {
  final EducationalResourceModel resource;
  final VoidCallback onTap;

  const ResourceFeedItem({
    Key? key,
    required this.resource,
    required this.onTap,
  }) : super(key: key);

  IconData _getFileTypeIcon() {
    switch (resource.fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'video':
      case 'mp4':
        return Icons.video_library;
      case 'audio':
      case 'mp3':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  

  Color _getFileTypeColor() {
    switch (resource.fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple;
      case 'video':
      case 'mp4':
        return Colors.red;
      case 'audio':
      case 'mp3':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo() {
    try {
      final dateTime = DateTime.parse(resource.createdAt as String);
      return timeago.format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with uploader info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      resource.uploaderName.isNotEmpty
                          ? resource.uploaderName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              resource.uploaderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (resource.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          _getTimeAgo(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'share') {
                        // Handle share
                      } else if (value == 'report') {
                        // Handle report
                      }
                    },
                    itemBuilder: (context) => [
                    
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag, size: 18),
                            SizedBox(width: 8),
                            Text('Report'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Title and description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resource.description,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Thumbnail or placeholder
            if (resource.thumbnailUrl.isNotEmpty || _hasVisualPreview())
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: resource.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: resource.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildPlaceholder(),
                          errorWidget: (context, url, error) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              )
            else
              // For non-visual resources, show a compact file info card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getFileTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getFileTypeColor().withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileTypeIcon(),
                      size: 36,
                      color: _getFileTypeColor(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${resource.fileType.toUpperCase()} Document',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getFileTypeColor(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap to view and download',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.download,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            
            // Categories and tags
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip(resource.category),
                  if (resource.subCategory.isNotEmpty)
                    _buildCategoryChip(resource.subCategory, isSubcategory: true),
                  ...resource.tags.take(3).map(_buildTagChip).toList(),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // Handle like
                    },
                    tooltip: 'Like',
                  ),
                  Row(
                    children: [
                      Text(
                        '${resource.likeCount}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    onPressed: () {
                      // Handle download
                    },
                    tooltip: 'Download',
                  ),
                  Row(
                    children: [
                      Text(
                        '${resource.downloadCount}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.download,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                
                  const Spacer(),
                
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _hasVisualPreview() {
    final fileType = resource.fileType.toLowerCase();
    return fileType == 'image' || 
           fileType == 'jpg' || 
           fileType == 'jpeg' || 
           fileType == 'png' || 
           fileType == 'video' || 
           fileType == 'mp4';
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          _getFileTypeIcon(),
          size: 48,
          color: _getFileTypeColor(),
        ),
      ),
    );
  }
  
  Widget _buildCategoryChip(String label, {bool isSubcategory = false}) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSubcategory ? Colors.black87 : Colors.white,
        ),
      ),
      backgroundColor: isSubcategory 
          ? Colors.grey[300]
          : MadadgarTheme.primaryColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
  
  Widget _buildTagChip(String tag) {
    return Chip(
      label: Text(
        '#$tag',
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
      backgroundColor: Colors.grey[200],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}