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
      final updatedResource =
          result['updatedResource'] as EducationalResourceModel?;

      if (action == 'updated' && updatedResource != null) {
        // Find the index of the updated resource
        final index = _resources.indexWhere((r) => r.id == resourceId);

        if (index != -1) {
          setState(() {
            // Replace the old resource with the updated one
            _resources[index] = updatedResource;
          });
        }
      } else if (action == 'deleted') {
        // If resource was deleted, refresh the entire list
        _loadResources();
      } else if (action == 'liked' || action == 'unliked') {
        // For like/unlike actions, always refresh to get the latest state
        // This ensures we get the real-time like count from the server
        if (_searchQuery.isEmpty) {
          // If not searching, reload by category
          final selectedCategory = _categories[_tabController.index];
          _loadResourcesByCategory(selectedCategory);
        } else {
          // If searching, perform the search again
          _searchResources(_searchQuery);
        }
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: MadadgarTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter Resources',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'File Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                      'All', Icons.all_inclusive, selectedFileType.isEmpty,
                      (value) {
                    setModalState(() => selectedFileType = '');
                  }),
                  _buildFilterChip(
                      'PDF', Icons.picture_as_pdf, selectedFileType == 'pdf',
                      (value) {
                    setModalState(() => selectedFileType = value ? 'pdf' : '');
                  }),
                  _buildFilterChip(
                      'Documents', Icons.description, selectedFileType == 'doc',
                      (value) {
                    setModalState(() => selectedFileType = value ? 'doc' : '');
                  }),
                  _buildFilterChip('Presentations', Icons.slideshow,
                      selectedFileType == 'ppt', (value) {
                    setModalState(() => selectedFileType = value ? 'ppt' : '');
                  }),
                  _buildFilterChip('Videos', Icons.play_circle_filled,
                      selectedFileType == 'video', (value) {
                    setModalState(
                        () => selectedFileType = value ? 'video' : '');
                  }),
                  _buildFilterChip(
                      'Images', Icons.image, selectedFileType == 'image',
                      (value) {
                    setModalState(
                        () => selectedFileType = value ? 'image' : '');
                  }),
                ],
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: verifiedOnly
                          ? MadadgarTheme.primaryColor
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Verified Resources Only'),
                  ],
                ),
                value: verifiedOnly,
                onChanged: (value) {
                  setModalState(() => verifiedOnly = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters(selectedFileType, verifiedOnly);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MadadgarTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
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
      String label, IconData icon, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: MadadgarTheme.primaryColor,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
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

  Widget _buildHeader() {
    final fontFamily = MadadgarTheme.fontFamily;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
      child: Row(
        children: [
          // Search field
          Expanded(
            child: _isSearchVisible
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search resources...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                              color: MadadgarTheme.primaryColor, width: 2),
                        ),
                        prefixIcon: Icon(Icons.search,
                            color: MadadgarTheme.primaryColor),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _toggleSearchVisibility,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        if (value.length >= 3 || value.isEmpty) {
                          _searchResources(value);
                        }
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Categories dropdown - moved to the right
          if (_categories.isNotEmpty)
            Container(
              height: 42,
              constraints: const BoxConstraints(maxWidth: 150),
              margin: EdgeInsets.only(
                left: _isSearchVisible ? 12 : 0,
                right: !_isSearchVisible ? 12 : 0,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(21),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 45),
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
                    final isSelected =
                        _categories[_tabController.index] == category;
                    return PopupMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 18,
                            color: isSelected
                                ? MadadgarTheme.primaryColor
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? MadadgarTheme.primaryColor
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category,
                        size: 16,
                        color: MadadgarTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _categories[_tabController.index],
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: MadadgarTheme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more,
                        size: 18,
                        color: MadadgarTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Action buttons
          if (!_isSearchVisible)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _toggleSearchVisibility,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search,
                      size: 22,
                      color: MadadgarTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(width: 10),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _showFilterDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 22,
                    color: MadadgarTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading resources...',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    color: Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    var fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Unable to load resources',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _loadResources,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    var fontFamily = MadadgarTheme.fontFamily;
    final primaryColor = MadadgarTheme.primaryColor;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.library_books_rounded,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'No educational resources found'
                  : 'No results for "$_searchQuery"',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Be the first to upload a resource and help the community learn',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _navigateToUploadResource,
              icon: const Icon(Icons.upload_rounded, size: 20),
              label: Text(
                'Upload Resource',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            // Loading indicator
            if (_isLoading)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: MadadgarTheme.primaryColor.withOpacity(0.7),
              ),

            // Content area
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _resources.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadResources,
                          color: MadadgarTheme.primaryColor,
                          backgroundColor: Colors.white,
                          strokeWidth: 2.5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _resources.length,
                              itemBuilder: (context, index) {
                                final resource = _resources[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 6),
                                  child: ResourceFeedItem(
                                    resource: resource,
                                    onTap: () =>
                                        _navigateToResourceDetail(resource),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MadadgarTheme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToUploadResource,
          elevation: 0,
          backgroundColor: MadadgarTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          tooltip: 'Upload Resource',
        ),
      ),
    );
  }
}
