// ignore_for_file: deprecated_member_use
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
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      case 'video':
      case 'mp4':
        return Icons.play_circle_fill_rounded;
      case 'audio':
      case 'mp3':
        return Icons.audio_file_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileTypeColor() {
    switch (resource.fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade600;
      case 'doc':
      case 'docx':
        return Colors.blue.shade600;
      case 'ppt':
      case 'pptx':
        return Colors.orange.shade600;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade600;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple.shade600;
      case 'video':
      case 'mp4':
        return Colors.red.shade600;
      case 'audio':
      case 'mp3':
        return Colors.cyan.shade600;
      default:
        return Colors.grey.shade600;
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
    final fontFamily = MadadgarTheme.fontFamily;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with uploader info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: MadadgarTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      resource.uploaderName.isNotEmpty
                          ? resource.uploaderName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        color: MadadgarTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      const SizedBox(height: 15),
                        Text(
                          resource.uploaderName,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        
                        // if (resource.isVerified)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 4),
                        //     child: Container(
                        //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //       decoration: BoxDecoration(
                        //         color: MadadgarTheme.primaryColor.withOpacity(0.2),
                        //         borderRadius: BorderRadius.circular(12),
                        //       ),
                        //       child: const Text(
                        //         'Verified Content',
                        //         style: TextStyle(
                        //           fontSize: 12,
                        //           fontWeight: FontWeight.w600,
                        //           color: Colors.black87, // or MadadgarTheme.primaryColor if preferred
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        Padding(
                          padding: EdgeInsets.only(top: resource.isVerified ? 4 : 0),
                          child: Text(
                            _getTimeAgo(),
                            style: TextStyle(
                              fontFamily: fontFamily,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'report') {
                        // Handle report
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_rounded, size: 18),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resource.description,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Thumbnail or placeholder
            if (resource.thumbnailUrl.isNotEmpty || _hasVisualPreview())
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
                ),
              )
            else
              // For non-visual resources, show a compact file info card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getFileTypeColor().withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getFileTypeColor().withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getFileTypeColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getFileTypeIcon(),
                        size: 24,
                        color: _getFileTypeColor(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${resource.fileType.toUpperCase()} Document',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _getFileTypeColor(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view and download',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Categories and tags
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip(resource.isVerified ? 'Verified Content' : 'Unverified Content'),
                  _buildCategoryChip(resource.category),
                  if (resource.subCategory.isNotEmpty)
                    _buildCategoryChip(resource.subCategory, isSubcategory: true),
                  ...resource.tags.take(2).map(_buildTagChip).toList(),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.favorite_border_rounded,
                    activeIcon: Icons.favorite_rounded,
                    count: resource.likeCount,
                    onPressed: () {
                      // Handle like
                    },
                    tooltip: 'Like',
                  ),
                  _buildActionButton(
                    icon: Icons.download_outlined,
                    activeIcon: Icons.download_rounded,
                    count: resource.downloadCount,
                    onPressed: () {
                      // Handle download
                    },
                    tooltip: 'Download',
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
  
  Widget _buildActionButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isActive ? activeIcon : icon,
            color: isActive ? MadadgarTheme.primaryColor : Colors.grey[600],
            size: 20,
          ),
          onPressed: onPressed,
          tooltip: tooltip,
          splashRadius: 24,
        ),
        Text(
          '$count',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
      ],
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
          color: _getFileTypeColor().withOpacity(0.7),
        ),
      ),
    );
  }
  
  Widget _buildCategoryChip(String label, {bool isSubcategory = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSubcategory 
            ? Colors.grey[200]
            : MadadgarTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSubcategory ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}