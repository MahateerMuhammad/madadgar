import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/models/post.dart';
import 'package:madadgar/services/post_service.dart';
import 'package:madadgar/services/auth_service.dart';
import 'package:madadgar/config/constants.dart';
import 'package:madadgar/config/theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  PostType _postType = PostType.need;
  String _title = '';
  String _description = '';
  String _category = AppConstants.categories.first;
  bool _isAnonymous = false;

  bool _isSubmitting = false;

  void _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final postService = Provider.of<PostService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) throw Exception("User not authenticated");

      final newPost = PostModel(
        id: '',
        userId: user.id,
        userName: _isAnonymous ? 'Anonymous' : user.name,
        userImage: _isAnonymous ? '' : user.profileImage,
        type: _postType,
        title: _title,
        description: _description,
        category: _category,
        region: user.region,
        isAnonymous: _isAnonymous,
        images: [], // image upload support can be added later
        status: PostStatus.active,
        viewCount: 0,
        respondCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await postService.addPost(newPost);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post created successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon:const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration:const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Post Type Selector
                Text(
                  'What are you creating?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTypeSelector(),
                const SizedBox(height: 24),
                
                // Title Field
                _buildTextField(
                  labelText: 'Title',
                  hintText: 'Enter a descriptive title',
                  prefixIcon: Icons.title,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter a title' : null,
                  onSaved: (value) => _title = value!,
                  maxLines: 1,
                ),
                const SizedBox(height: 20),
                
                // Description Field
                _buildTextField(
                  labelText: 'Description',
                  hintText: 'Describe your need or offer in detail',
                  prefixIcon: Icons.description,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter a description'
                      : null,
                  onSaved: (value) => _description = value!,
                  maxLines: 5,
                ),
                const SizedBox(height: 20),
                
                // Category Dropdown
                _buildCategoryDropdown(),
                const SizedBox(height: 20),
                
                // Anonymous toggle
                _buildAnonymousToggle(),
                const SizedBox(height: 30),
                
                // Submit button
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeSelectorButton(
              type: PostType.need,
              label: 'I Need Help',
              icon: Icons.help_outline,
            ),
          ),
          Expanded(
            child: _buildTypeSelectorButton(
              type: PostType.offer,
              label: 'I Can Help',
              icon: Icons.volunteer_activism,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypeSelectorButton({
    required PostType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _postType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _postType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? MadadgarTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(prefixIcon, color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          maxLines: maxLines,
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }
  
  Widget _buildCategoryDropdown() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Category',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.grey.shade700,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          value: _category,
          icon: Icon(
            Icons.keyboard_arrow_down, 
            color: Colors.grey.shade700,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.category, 
              color: Colors.grey.shade500,
              size: 22,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: MadadgarTheme.primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 15,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          items: AppConstants.categories
              .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _category = value!),
        ),
      ),
    ],
  );
}

  Widget _buildAnonymousToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              _isAnonymous ? Icons.visibility_off : Icons.visibility,
              color: _isAnonymous 
                ? MadadgarTheme.primaryColor 
                : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Post Anonymously',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _isAnonymous 
              ? 'Your identity will be hidden' 
              : 'Your name will be visible',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: _isAnonymous,
        onChanged: (val) => setState(() => _isAnonymous = val),
        activeColor: MadadgarTheme.primaryColor,
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: MadadgarTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      onPressed: _isSubmitting ? null : _submitPost,
      child: _isSubmitting
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text(
                  'Publish Post',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}