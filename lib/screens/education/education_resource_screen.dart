import 'package:flutter/material.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/models/education.dart';
import 'package:madadgar/services/edu_service.dart';
import 'package:madadgar/screens/education/resource_detail_screen.dart';
import 'package:madadgar/screens/education/upload_resource_screen.dart';
import 'package:madadgar/widgets/resource_card.dart';

class EducationalResourcesScreen extends StatefulWidget {
  const EducationalResourcesScreen({Key? key}) : super(key: key);

  @override
  State<EducationalResourcesScreen> createState() =>
      _EducationalResourcesScreenState();
}

class _EducationalResourcesScreenState extends State<EducationalResourcesScreen>
    with SingleTickerProviderStateMixin {
  final EducationalResourceService _resourceService =
      EducationalResourceService();
  late TabController _tabController;
  List<EducationalResourceModel> _resources = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadCategories();
    await _loadResources();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _resourceService.getAvailableCategories();
      setState(() {
        _categories = ['All', ...categories];
        _tabController = TabController(length: _categories.length, vsync: this);

        // Add listener to tab controller to handle tab changes
        _tabController.addListener(_handleTabChange);
      });
    } catch (e) {
      print("Error loading categories: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  // Handle tab changes
  void _handleTabChange() {
    // Only react to user taps, not programmatic changes
    if (_tabController.indexIsChanging) {
      return;
    }

    final selectedCategory = _categories[_tabController.index];
    _loadResourcesByCategory(selectedCategory);
  }

  Future<void> _loadResources() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final resources = await _resourceService.getAllResources(limit: 50);
      if (mounted) {
        setState(() {
          _resources = resources;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading resources: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load resources: $e')),
        );
      }
    }
  }

  Future<void> _loadResourcesByCategory(String category) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<EducationalResourceModel> resources;
      if (category == 'All') {
        resources = await _resourceService.getAllResources(limit: 50);
      } else {
        resources =
            await _resourceService.getResourcesByCategory(category, limit: 50);
      }

      if (mounted) {
        setState(() {
          _resources = resources;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading resources by category: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load resources: $e')),
        );
      }
    }
  }

  Future<void> _searchResources(String query) async {
    if (query.isEmpty) {
      _loadResources();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final resources =
          await _resourceService.searchResources(query, limit: 50);
      if (mounted) {
        setState(() {
          _resources = resources;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error searching resources: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search resources: $e')),
        );
      }
    }
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
      // Find the index of the updated resource
      final index = _resources.indexWhere((r) => r.id == resourceId);
      
      if (index != -1) {
        setState(() {
          // Replace the old resource with the updated one
          _resources[index] = updatedResource;
        });
      }
    } else if (result['action'] == 'deleted') {
      // If resource was deleted, refresh the entire list
      _loadResources();
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
      _loadResources();
    }
  }

  void _toggleSearchVisibility() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchResources('');
      }
    });
  }

  void _showFilterDialog() {
    String selectedFileType = '';
    bool verifiedOnly = false;

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
                  'Filter Resources',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'File Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', selectedFileType.isEmpty, (value) {
                    setModalState(() => selectedFileType = '');
                  }),
                  _buildFilterChip('PDF', selectedFileType == 'pdf', (value) {
                    setModalState(() => selectedFileType = value ? 'pdf' : '');
                  }),
                  _buildFilterChip('Documents', selectedFileType == 'doc',
                      (value) {
                    setModalState(() => selectedFileType = value ? 'doc' : '');
                  }),
                  _buildFilterChip('Presentations', selectedFileType == 'ppt',
                      (value) {
                    setModalState(() => selectedFileType = value ? 'ppt' : '');
                  }),
                  _buildFilterChip('Videos', selectedFileType == 'video',
                      (value) {
                    setModalState(
                        () => selectedFileType = value ? 'video' : '');
                  }),
                  _buildFilterChip('Images', selectedFileType == 'image',
                      (value) {
                    setModalState(
                        () => selectedFileType = value ? 'image' : '');
                  }),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Verified Resources Only'),
                value: verifiedOnly,
                onChanged: (value) {
                  setModalState(() => verifiedOnly = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters(selectedFileType, verifiedOnly);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _applyFilters(String fileType, bool verifiedOnly) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resources = await _resourceService.advancedSearch(
        fileType: fileType,
        isVerified: verifiedOnly ? true : null,
        limit: 50,
      );

      setState(() {
        _resources = resources;
        _isLoading = false;
      });
    } catch (e) {
      print("Error applying filters: $e");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply filters: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Custom tab widget with minimal design
  Widget _buildCategoryTab(String category, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? MadadgarTheme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? MadadgarTheme.primaryColor : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Combined search, categories and filter row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Categories dropdown
                  if (_categories.isNotEmpty)
                    Container(
                      height: 40,
                      constraints: const BoxConstraints(maxWidth: 300),
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        onSelected: (value) {
                          final index = _categories.indexOf(value);
                          if (index != -1) {
                            _tabController.animateTo(index);
                            _loadResourcesByCategory(value);
                          }
                        },
                        itemBuilder: (context) {
                          return _categories.map((category) {
                            return PopupMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontWeight:
                                      _categories[_tabController.index] ==
                                              category
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _categories[_tabController.index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Search field
                  Expanded(
                    child: _isSearchVisible
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search resources...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                    color: MadadgarTheme.primaryColor),
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _toggleSearchVisibility,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onChanged: (value) {
                              if (value.length >= 3 || value.isEmpty) {
                                _searchResources(value);
                              }
                            },
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Action buttons
                  if (!_isSearchVisible)
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.grey),
                      onPressed: _toggleSearchVisibility,
                    ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.grey),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
            ),

            // Loading indicator - more subtle
            if (_isLoading)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: MadadgarTheme.primaryColor.withOpacity(0.7),
              ),
            // Content area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _resources.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No educational resources found'
                                    : 'No results for "$_searchQuery"',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade500),
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
                        )
                      : RefreshIndicator(
                          onRefresh: _loadResources,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 80),
                            itemCount: _resources.length,
                            itemBuilder: (context, index) {
                              final resource = _resources[index];
                              return ResourceFeedItem(
                                resource: resource,
                                onTap: () =>
                                    _navigateToResourceDetail(resource),
                              );
                            },
                          ),
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
