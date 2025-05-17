import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:madadgar/models/education.dart';
import 'package:madadgar/services/user_service.dart';

class EducationalResourceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final String _collectionName = 'educational_resources';
  final String _likesCollectionName = 'resource_likes'; 
  
  
  final String cloudName = "ddppfyrcv";
  final String presetName = "madadgar";
  final String uploadUrl = "https://api.cloudinary.com/v1_1/ddppfyrcv/auto/upload";

  // Hardcoded categories and subcategories
  final Map<String, List<String>> _categoriesMap = {
    'Academic': ['Mathematics', 'Science', 'History', 'Languages', 'Literature', 'Computer Science'],
    'Professional': ['Business', 'Engineering', 'Medicine', 'Law', 'Teaching', 'Design'],
    'Skills': ['Programming', 'Art', 'Music', 'Cooking', 'Gardening', 'Photography'],
    'Reference': ['Textbooks', 'Research Papers', 'Guides', 'Manuals', 'Dictionaries'],
    'Career': ['Resume Templates', 'Interview Preparation', 'Job Search Resources', 'Career Advice'],
    'Other': [],
  };

  // Hardcoded popular tags
  final List<String> _popularTags = [
    'beginner', 'advanced', 'tutorial', 'exercise', 'practice', 
    'reference', 'exam', 'homework', 'project', 'research',
    'free', 'comprehensive', 'interactive', 'latest', 'popular'
  ];

  // Get all educational resources
  Future<List<EducationalResourceModel>> getAllResources({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting educational resources: $e");
      rethrow;
    }
  }

  // Get resources by category
  Future<List<EducationalResourceModel>> getResourcesByCategory(String category, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting resources by category: $e");
      rethrow;
    }
  }

  // Get resources by subcategory
  Future<List<EducationalResourceModel>> getResourcesBySubCategory(String subCategory, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('subCategory', isEqualTo: subCategory)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting resources by subcategory: $e");
      rethrow;
    }
  }

  // Get resources by file type
  Future<List<EducationalResourceModel>> getResourcesByFileType(String fileType, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('fileType', isEqualTo: fileType)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting resources by file type: $e");
      rethrow;
    }
  }

  // Get resources by tag
  Future<List<EducationalResourceModel>> getResourcesByTag(String tag, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('tags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting resources by tag: $e");
      rethrow;
    }
  }

  // Get resources by uploader
  Future<List<EducationalResourceModel>> getResourcesByUploader(String uploaderId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('uploaderId', isEqualTo: uploaderId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting resources by uploader: $e");
      rethrow;
    }
  }

  // Get resources by verification status
  Future<List<EducationalResourceModel>> getVerifiedResources({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isVerified', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting verified resources: $e");
      rethrow;
    }
  }

  // Get most downloaded resources
  Future<List<EducationalResourceModel>> getMostDownloadedResources({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('downloadCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting most downloaded resources: $e");
      rethrow;
    }
  }

  // Get most liked resources
  Future<List<EducationalResourceModel>> getMostLikedResources({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('likeCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error getting most liked resources: $e");
      rethrow;
    }
  }

  // Get resource by ID
  Future<EducationalResourceModel> getResourceById(String resourceId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(resourceId).get();

      if (!doc.exists) {
        throw Exception('Resource not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      return EducationalResourceModel.fromMap(data);
    } catch (e) {
      print("Error getting resource by ID: $e");
      rethrow;
    }
  }

  // Search resources by title and description
  Future<List<EducationalResourceModel>> searchResources(String searchQuery, {int limit = 20}) async {
    try {
      // Get all resources (this is not efficient for large datasets,
      // consider implementing a proper search index for production)
      final querySnapshot = await _firestore.collection(_collectionName).get();

      final searchTermLower = searchQuery.toLowerCase();

      // Filter resources whose title or description contain the search term
      final filteredDocs = querySnapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] as String? ?? '').toLowerCase();
            final description = (data['description'] as String? ?? '').toLowerCase();
            return title.contains(searchTermLower) || description.contains(searchTermLower);
          })
          .take(limit)
          .toList();

      return filteredDocs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error searching resources: $e");
      rethrow;
    }
  }

  // Advanced search with filters
  Future<List<EducationalResourceModel>> advancedSearch({
    String? searchQuery,
    String? category,
    String? subCategory,
    String? fileType,
    List<String>? tags,
    bool? isVerified,
    int limit = 20,
  }) async {
    try {
      // Start with all resources
      Query query = _firestore.collection(_collectionName);

      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (subCategory != null && subCategory.isNotEmpty) {
        query = query.where('subCategory', isEqualTo: subCategory);
      }

      if (fileType != null && fileType.isNotEmpty) {
        query = query.where('fileType', isEqualTo: fileType);
      }

      if (isVerified != null) {
        query = query.where('isVerified', isEqualTo: isVerified);
      }

      // Get results
      final querySnapshot = await query.get();

      // Filter by search query
      var filteredDocs = querySnapshot.docs;
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTermLower = searchQuery.toLowerCase();
        filteredDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = ((data['title'] ?? '') as String).toLowerCase();
          final description = ((data['description'] ?? '') as String).toLowerCase();
          return title.contains(searchTermLower) || description.contains(searchTermLower);
        }).toList();
      }

      // Filter by tags (if any)
      if (tags != null && tags.isNotEmpty) {
        filteredDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final resourceTags = List<String>.from(data['tags'] ?? []);
          return tags.any((tag) => resourceTags.contains(tag));
        }).toList();
      }

      // Sort by latest first and limit
      filteredDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aDate = DateTime.parse((aData['createdAt'] ?? '').toString());
        final bDate = DateTime.parse((bData['createdAt'] ?? '').toString());
        return bDate.compareTo(aDate);
      });

      filteredDocs = filteredDocs.take(limit).toList();

      return filteredDocs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return EducationalResourceModel.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error in advanced search: $e");
      rethrow;
    }
  }

  // Upload file to Cloudinary
  Future<Map<String, dynamic>> uploadToCloudinary(File file) async {
    try {
      // Determine file mime type
      final mimeTypeData = lookupMimeType(file.path)?.split('/');
      final fileType = mimeTypeData?[0] ?? 'application';
      final fileExtension = mimeTypeData?[1] ?? 'octet-stream';
      
      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: path.basename(file.path),
          contentType: MediaType(fileType, fileExtension),
        ),
        'upload_preset': presetName,
      });

      // Upload to Cloudinary
      final response = await Dio().post(
        uploadUrl,
        data: formData,
        options: Options(headers: {
          'Content-Type': 'multipart/form-data',
        }),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to upload file');
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      rethrow;
    }
  }

  // Create new educational resource
  Future<EducationalResourceModel> createResource({
    required String title,
    required String description,
    required File file,
    required String category,
    String? subCategory,
    List<String>? tags,
  }) async {
    try {
      // Check auth
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user name
      final uploaderName = await _userService.getCurrentUsername();
      
      // Upload file to Cloudinary
      final uploadResult = await uploadToCloudinary(file);
      
      // Determine file type based on format or resource_type
      String fileType = uploadResult['format'] ?? '';
      if (fileType.isEmpty) {
        final resourceType = uploadResult['resource_type'] ?? 'file';
        fileType = resourceType;
      }

      // Create resource document
      final resourceData = {
        'title': title,
        'description': description,
        'resourceUrl': uploadResult['secure_url'],
        'thumbnailUrl': uploadResult['resource_type'] == 'image' 
            ? uploadResult['secure_url'] 
            : (uploadResult['thumbnail_url'] ?? ''),
        'fileType': fileType,
        'category': category,
        'subCategory': subCategory ?? '',
        'uploaderId': user.uid,
        'uploaderName': uploaderName,
        'downloadCount': 0,
        'likeCount': 0,
        'tags': tags ?? [],
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore
      final docRef = await _firestore.collection(_collectionName).add(resourceData);
      
      // Update id field
      await docRef.update({'id': docRef.id});
      
      // Return the created resource
      resourceData['id'] = docRef.id;
      return EducationalResourceModel.fromMap(resourceData);
    } catch (e) {
      print("Error creating resource: $e");
      rethrow;
    }
  }

  // Update resource
  Future<void> updateResource(String resourceId, Map<String, dynamic> fields) async {
    try {
      // Add updated timestamp
      fields['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection(_collectionName).doc(resourceId).update(fields);
    } catch (e) {
      print("Error updating resource: $e");
      rethrow;
    }
  }

  // Delete resource
  Future<void> deleteResource(String resourceId) async {
    try {
      await _firestore.collection(_collectionName).doc(resourceId).delete();
      
      // Delete all likes records for this resource
      final likesQuery = await _firestore
          .collection(_likesCollectionName)
          .where('resourceId', isEqualTo: resourceId)
          .get();
      
      // Batch delete all like documents
      final batch = _firestore.batch();
      for (var doc in likesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Note: This doesn't delete the file from Cloudinary
      // You would need to implement a separate Cloudinary deletion 
      // if you want to remove the file as well
    } catch (e) {
      print("Error deleting resource: $e");
      rethrow;
    }
  }

  // Check if user can download resource
  Future<bool> canDownloadResource(String resourceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false; // User not authenticated
      }

      // Get the resource
      final resource = await getResourceById(resourceId);
      
      // Check if user is the owner (owners can't download their own resources)
      return resource.uploaderId != user.uid;
    } catch (e) {
      print("Error checking download permission: $e");
      return false;
    }
  }

  // Increment download count
  Future<void> incrementDownloadCount(String resourceId) async {
    try {
      // Check if user can download
      if (!await canDownloadResource(resourceId)) {
        throw Exception('You cannot download your own resource');
      }
      
      await _firestore.collection(_collectionName).doc(resourceId).update({
        'downloadCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error incrementing download count: $e");
      rethrow;
    }
  }

  // Check if current user has already liked a resource
  Future<bool> hasUserLikedResource(String resourceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false; // User not authenticated
      }

      // Check if a like document exists for this user and resource
      final likeDoc = await _firestore
          .collection(_likesCollectionName)
          .where('userId', isEqualTo: user.uid)
          .where('resourceId', isEqualTo: resourceId)
          .limit(1)
          .get();

      return likeDoc.docs.isNotEmpty;
    } catch (e) {
      print("Error checking if user liked resource: $e");
      return false;
    }
  }

  // Check if user can like resource
  Future<bool> canLikeResource(String resourceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false; // User not authenticated
      }

      // Get the resource
      final resource = await getResourceById(resourceId);
      
      // Check if user is the owner (owners can't like their own resources)
      if (resource.uploaderId == user.uid) {
        return false;
      }
      
      // Check if user has already liked this resource
      final hasLiked = await hasUserLikedResource(resourceId);
      return !hasLiked;
    } catch (e) {
      print("Error checking like permission: $e");
      return false;
    }
  }

  // Like/unlike resource
  Future<bool> toggleLike(String resourceId, bool isLiked) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the resource to check ownership
      final resource = await getResourceById(resourceId);
      
      // Check if user is the owner
      if (resource.uploaderId == user.uid) {
        throw Exception('You cannot like your own resource');
      }

      // Check if the user has already liked this resource
      final hasLiked = await hasUserLikedResource(resourceId);
      
      // If trying to like and already liked, or trying to unlike and not liked, then return
      if ((isLiked && hasLiked) || (!isLiked && !hasLiked)) {
        return false; // No change needed
      }

      if (isLiked) {
        // Create a like record
        await _firestore.collection(_likesCollectionName).add({
          'userId': user.uid,
          'resourceId': resourceId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // Increment like count
        await _firestore.collection(_collectionName).doc(resourceId).update({
          'likeCount': FieldValue.increment(1),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Find and delete the like record
        final likeQuery = await _firestore
            .collection(_likesCollectionName)
            .where('userId', isEqualTo: user.uid)
            .where('resourceId', isEqualTo: resourceId)
            .limit(1)
            .get();
        
        if (likeQuery.docs.isNotEmpty) {
          await _firestore.collection(_likesCollectionName).doc(likeQuery.docs.first.id).delete();
          
          // Decrement like count
          await _firestore.collection(_collectionName).doc(resourceId).update({
            'likeCount': FieldValue.increment(-1),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
      
      return true; // Successfully toggled like
    } catch (e) {
      print("Error toggling like: $e");
      rethrow;
    }
  }

  // Update verification status
  Future<void> updateVerificationStatus(String resourceId, bool isVerified) async {
    try {
      await _firestore.collection(_collectionName).doc(resourceId).update({
        'isVerified': isVerified,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error updating verification status: $e");
      rethrow;
    }
  }

  // Get available categories - MODIFIED to use hardcoded values
  Future<List<String>> getAvailableCategories() async {
    // Return hardcoded categories
    return _categoriesMap.keys.toList();
  }

  // Get available subcategories for a specific category - MODIFIED to use hardcoded values
  Future<List<String>> getAvailableSubCategories(String category) async {
    // Return hardcoded subcategories for the given category
    return _categoriesMap[category] ?? [];
  }

  // Get all tags used in resources - MODIFIED to use hardcoded values
  Future<List<String>> getAllTags() async {
    // Return popular hardcoded tags
    return _popularTags;
  }
}