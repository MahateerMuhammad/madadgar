// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:madadgar/models/education.dart';
import 'package:madadgar/services/edu_service.dart';
import 'package:madadgar/config/theme.dart';
import 'package:path/path.dart' as path;

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({Key? key}) : super(key: key);

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final EducationalResourceService _resourceService = EducationalResourceService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  List<String> _selectedTags = [];
  
  File? _selectedFile;
  String _fileName = '';
  bool _isUploading = false;
  
  List<String> _categories = [];
  List<String> _subCategories = [];
  List<String> _availableTags = [];
  
  double _uploadProgress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadTags();
  }
  
  Future<void> _loadCategories() async {
    try {
      final categories = await _resourceService.getAvailableCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategory = categories[0];
          _loadSubCategories(categories[0]);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load categories: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
  
  Future<void> _loadSubCategories(String category) async {
    try {
      final subCategories = await _resourceService.getAvailableSubCategories(category);
      setState(() {
        _subCategories = subCategories;
        _selectedSubCategory = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load subcategories: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
  
  Future<void> _loadTags() async {
    try {
      final tags = await _resourceService.getAllTags();
      setState(() {
        _availableTags = tags;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tags: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
  
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          _selectedFile = file;
          _fileName = path.basename(file.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
  
  Future<void> _uploadResource() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a file to upload'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    
    try {
      // First simulate progress updates (for better UX since our service doesn't provide real-time progress)
      _simulateProgressUpdates();
      
      final resource = await _resourceService.createResource(
        title: _titleController.text,
        description: _descriptionController.text,
        file: _selectedFile!,
        category: _selectedCategory,
        subCategory: _selectedSubCategory.isNotEmpty ? _selectedSubCategory : null,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
      );
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Resource uploaded successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      
      // Return to previous screen
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload resource: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
  
  void _simulateProgressUpdates() {
    // Simulate progress updates at regular intervals
    const totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      Future.delayed(Duration(milliseconds: 500 * i), () {
        if (mounted && _isUploading) {
          setState(() {
            _uploadProgress = i / totalSteps;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Upload Resource',
          style: TextStyle(
            color: MadadgarTheme.primaryColor,
            fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
         
          icon: const Icon(Icons.arrow_back_ios_new, size: 20,color: MadadgarTheme.primaryColor,),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isUploading
          ? _buildUploadingView()
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: _buildUploadForm(),
              ),
            ),
    );
  }
  
  Widget _buildUploadingView() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Uploading Resource',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(MadadgarTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            if (_uploadProgress < 1.0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Please wait while we upload your resource.\nThis may take a few minutes depending on file size.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUploadForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // Title Field
          _buildTextField(
            labelText: 'Title',
            hintText: 'Enter a descriptive title',
            prefixIcon: Icons.title,
            controller: _titleController,
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter a title' : null,
            maxLines: 1,
          ),
          const SizedBox(height: 20),
          
          // Description Field
          _buildTextField(
            labelText: 'Description',
            hintText: 'Describe your educational resource in detail',
            prefixIcon: Icons.description,
            controller: _descriptionController,
            validator: (value) => value == null || value.isEmpty
                ? 'Enter a description'
                : null,
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          
          // Category Dropdown
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          
          // SubCategory Dropdown (if available)
          if (_subCategories.isNotEmpty)
            _buildSubCategoryDropdown(),
          if (_subCategories.isNotEmpty)
            const SizedBox(height: 20),
          
          // Tags Input
          _buildTagsInput(),
          const SizedBox(height: 20),
          
          // File Selection
          _buildFileSelector(),
          const SizedBox(height: 30),
          
          // Upload Button
          _buildUploadButton(),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required TextEditingController controller,
    required String? Function(String?) validator,
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
          controller: controller,
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
            value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
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
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
                _loadSubCategories(value);
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
      ],
    );
  }
  
  Widget _buildSubCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subcategory (Optional)',
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
            value: _selectedSubCategory.isNotEmpty ? _selectedSubCategory : null,
            icon: Icon(
              Icons.keyboard_arrow_down, 
              color: Colors.grey.shade700,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.subdirectory_arrow_right, 
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
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('None'),
              ),
              ..._subCategories.map((subCategory) {
                return DropdownMenuItem<String>(
                  value: subCategory,
                  child: Text(subCategory),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSubCategory = value ?? '';
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags (Optional)',
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags display
              if (_selectedTags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedTags.map((tag) {
                    return Container(
                      decoration: BoxDecoration(
                        color: MadadgarTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTags.remove(tag);
                              });
                            },
                            child: const Icon(
                              Icons.cancel,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              
              if (_selectedTags.isNotEmpty)
                const SizedBox(height: 12),
              
              // Text field for new tags
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '   Add a tag...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
             
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !_selectedTags.contains(value)) {
                          setState(() {
                            _selectedTags.add(value.trim());
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              // Show suggestions
              if (_availableTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested tags:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTags
                            .where((tag) => !_selectedTags.contains(tag))
                            .take(8) // Limit suggestions to avoid cluttering
                            .map((tag) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTags.add(tag);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
  
  Widget _buildFileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resource File',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName.isNotEmpty ? _fileName : 'Tap to select a file',
                        style: TextStyle(
                          color: _fileName.isNotEmpty ? Colors.grey.shade800 : Colors.grey.shade500,
                          fontWeight: _fileName.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Size: ${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: MadadgarTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUploadButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: MadadgarTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      onPressed: _isUploading ? null : _uploadResource,
      child: _isUploading
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
                Icon(Icons.cloud_upload),
                SizedBox(width: 8),
                Text(
                  'Upload Resource',
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