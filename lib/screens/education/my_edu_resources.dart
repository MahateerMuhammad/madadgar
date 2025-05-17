import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/models/education.dart';
import 'package:madadgar/services/edu_service.dart';
import 'package:madadgar/screens/education/resource_detail_screen.dart';
import 'package:madadgar/screens/education/upload_resource_screen.dart';
import 'package:madadgar/widgets/resource_card.dart';

class MyResourcesScreen extends StatefulWidget {
  const MyResourcesScreen({Key? key}) : super(key: key);

  @override
  State<MyResourcesScreen> createState() => _MyResourcesScreenState();
}

class _MyResourcesScreenState extends State<MyResourcesScreen> {
  final EducationalResourceService _resourceService = EducationalResourceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<EducationalResourceModel> _myResources = [];
  List<EducationalResourceModel> _filteredResources = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter options
  String _selectedCategory = 'All';
  String _selectedFileType = 'All';
  String _sortBy = 'Latest'; // Latest, Oldest, Most Downloaded, Most Liked
  
  @override
  void initState() {
    super.initState();
    _loadMyResources();
  }

  Future<void> _loadMyResources() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final resources = await _resourceService.getResourcesByUploader(user.uid, limit: 100);
      
      if (mounted) {
        setState(() {
          _myResources = resources;
          _filteredResources = resources;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading my resources: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load your resources: $e')),
        );
      }
    }
  }

  void _filterAndSearchResources() {
    List<EducationalResourceModel> filtered = List.from(_myResources);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((resource) {
        final title = resource.title.toLowerCase();
        final description = resource.description.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((resource) => resource.category == _selectedCategory).toList();
    }

    // Apply file type filter
    if (_selectedFileType != 'All') {
      filtered = filtered.where((resource) => resource.fileType == _selectedFileType).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Latest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Most Downloaded':
        filtered.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
        break;
      case 'Most Liked':
        filtered.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;
    }

    setState(() {
      _filteredResources = filtered;
    });
  }

  void _navigateToResourceDetail(EducationalResourceModel resource) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ResourceDetailScreen(resource: resource),
      ),
    );
    
    if (result != null) {
      final String? action = result['action'] as String?;
      final String resourceId = result['resourceId'] as String;
      final updatedResource = result['updatedResource'] as EducationalResourceModel?;
      
      if (updatedResource != null) {
        // Find the index in both lists and update
        final myIndex = _myResources.indexWhere((r) => r.id == resourceId);
        final filteredIndex = _filteredResources.indexWhere((r) => r.id == resourceId);
        
        setState(() {
          if (myIndex != -1) _myResources[myIndex] = updatedResource;
          if (filteredIndex != -1) _filteredResources[filteredIndex] = updatedResource;
        });
      } else if (action == 'deleted') {
        // Remove from both lists
        setState(() {
          _myResources.removeWhere((r) => r.id == resourceId);
          _filteredResources.removeWhere((r) => r.id == resourceId);
        });
      }
    }
  }

  void _navigateToUploadResource() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadResourceScreen(),
      ),
    );

    if (result == true) {
      _loadMyResources();
    }
  }

  void _toggleSearchVisibility() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _filterAndSearchResources();
      }
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category Filter
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Academic', 'Professional', 'Skills', 'Reference', 'Career', 'Other']
                    .map((category) => _buildFilterChip(
                      category, 
                      _selectedCategory == category, 
                      (selected) => setModalState(() => _selectedCategory = category),
                    )).toList(),
              ),
              const SizedBox(height: 16),
              
              // File Type Filter
              const Text('File Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'pdf', 'doc', 'ppt', 'video', 'image']
                    .map((fileType) => _buildFilterChip(
                      fileType.toUpperCase(), 
                      _selectedFileType == fileType, 
                      (selected) => setModalState(() => _selectedFileType = fileType),
                    )).toList(),
              ),
              const SizedBox(height: 16),
              
              // Sort Options
              const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Latest', 'Oldest', 'Most Downloaded', 'Most Liked']
                    .map((sortOption) => _buildFilterChip(
                      sortOption, 
                      _sortBy == sortOption, 
                      (selected) => setModalState(() => _sortBy = sortOption),
                    )).toList(),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // Reset filters
                      setModalState(() {
                        _selectedCategory = 'All';
                        _selectedFileType = 'All';
                        _sortBy = 'Latest';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filterAndSearchResources();
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: MadadgarTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalResources = _myResources.length;
    final totalDownloads = _myResources.fold<int>(0, (sum, resource) => sum + resource.downloadCount);
    final totalLikes = _myResources.fold<int>(0, (sum, resource) => sum + resource.likeCount);
    final verifiedCount = _myResources.where((resource) => resource.isVerified).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.folder, 'Resources', totalResources.toString()),
          _buildStatItem(Icons.download, 'Downloads', totalDownloads.toString()),
          _buildStatItem(Icons.favorite, 'Likes', totalLikes.toString()),
          _buildStatItem(Icons.verified, 'Verified', verifiedCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: MadadgarTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
         leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20,color: MadadgarTheme.primaryColor,),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Resources',
          style: TextStyle(fontWeight: FontWeight.bold,color: MadadgarTheme.primaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          if (_isSearchVisible)
            Container(
              width: 200,
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _toggleSearchVisibility,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterAndSearchResources();
                },
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearchVisibility,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyResources,
        child: Column(
          children: [
            // Stats Card
            if (!_isLoading && _myResources.isNotEmpty) _buildStatsCard(),

            // Loading indicator
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredResources.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedFileType != 'All'
                            ? Icons.search_off
                            : Icons.book_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedFileType != 'All'
                            ? 'No resources found with current filters'
                            : 'You haven\'t uploaded any resources yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _navigateToUploadResource,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Upload Your First Resource'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _filteredResources.length,
                  itemBuilder: (context, index) {
                    final resource = _filteredResources[index];
                    return ResourceFeedItem(
                      resource: resource,
                      onTap: () => _navigateToResourceDetail(resource),
                      // Custom parameter to show edit/delete actions
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUploadResource,
        elevation: 2,
        backgroundColor: MadadgarTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Upload Resource',
      ),
    );
  }
}