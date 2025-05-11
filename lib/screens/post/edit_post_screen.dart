import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/config/theme.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedCategory = '';
  String _selectedRegion = '';
  bool _isAnonymous = false;
  bool _isLoading = false;

 @override
void initState() {
    super.initState();

    
    print('Category: ${widget.post.category}, Region: ${widget.post.region}'); // Debugging Line
    // Initialize controllers with existing post data
    _titleController = TextEditingController(text: widget.post.title);
    _descriptionController = TextEditingController(text: widget.post.description);
    _selectedCategory = widget.post.category;
    _selectedRegion = widget.post.region;
    _isAnonymous = widget.post.isAnonymous;
}

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // List of supported categories (add your own)
  final List<String> _categories = [
    'Food',
    'Clothing',
    'Education',
    'Medical',
    'Services',
    'Shelter',
    'Other',
  ];

  // List of supported regions (add your own)
 final List<String> _regions = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Peshawar',
    'Quetta',
    'Multan', // Make sure this matches what you expect
    'Faisalabad',
    'Hyderabad',
    'Rawalpindi',
    'Other'
];

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final postService = Provider.of<PostService>(context, listen: false);
      
      // Create updated post using copyWith
      final updatedPost = widget.post.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        region: _selectedRegion,
        isAnonymous: _isAnonymous,
      );
      
      await postService.updatePost(updatedPost);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show success message and pop back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Post updated successfully',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
              ),
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Navigator.of(context).pop(true); // Return true to indicate successful update
      }
    } catch (e) {
      print("Error updating post: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating post: ${e.toString()}',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
              ),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edit Post',
          style: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post type indicator (cannot be changed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.post.type == PostType.offer 
                              ? const Color(0xFF2E7D32).withOpacity(0.1) 
                              : const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.post.type == PostType.offer 
                                ? const Color(0xFF2E7D32).withOpacity(0.3) 
                                : const Color(0xFF1565C0).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.post.type == PostType.offer 
                                  ? Icons.volunteer_activism_rounded 
                                  : Icons.help_outline_rounded,
                              color: widget.post.type == PostType.offer 
                                  ? const Color(0xFF2E7D32) 
                                  : const Color(0xFF1565C0),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.post.type == PostType.offer ? 'OFFER' : 'NEED',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontWeight: FontWeight.bold,
                                color: widget.post.type == PostType.offer 
                                    ? const Color(0xFF2E7D32) 
                                    : const Color(0xFF1565C0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(cannot be changed)',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Title field
                      Text(
                        'Title',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter post title',
                          hintStyle: TextStyle(
                            fontFamily: fontFamily,
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Title must be at least 5 characters long';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Description field
                      Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 16,
                        ),
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Enter post description',
                          hintStyle: TextStyle(
                            fontFamily: fontFamily,
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          if (value.trim().length < 20) {
                            return 'Description must be at least 20 characters long';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Category dropdown
                      Text(
                        'Category',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Region dropdown
                      Text(
                        'Region',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextFormField(
                          initialValue: _selectedRegion,
                          decoration: InputDecoration(
                            labelText: 'Region',
                            border: OutlineInputBorder(),
                          ),
                          enabled: false, // Makes it read-only
                        ),
                        ),

                      
                      
                      const SizedBox(height: 20),
                      
                      // Anonymous toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility_off_outlined,
                                  color: _isAnonymous ? primaryColor : Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Post Anonymously',
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Text(
                                      'Your name will not be visible to others',
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: _isAnonymous,
                              activeColor: primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  _isAnonymous = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Update button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _updatePost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'UPDATE POST',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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