// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:madadgar/models/location.dart';
// import 'package:madadgar/config/constants.dart';

// class LocationService extends ChangeNotifier {
//   LocationModel? _currentLocation;
//   LocationModel? get currentLocation => _currentLocation;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   LocationService() {
//     _loadSavedLocation();
//   }

//   Future<void> _loadSavedLocation() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final locationName = prefs.getString('location_name') ?? 'Unknown';
//       final locationCity = prefs.getString('location_city') ?? 'Unknown';
//       final locationRegion = prefs.getString('location_region') ?? 'Unknown';
//       final locationLat = prefs.getDouble('location_lat') ?? 0.0;
//       final locationLng = prefs.getDouble('location_lng') ?? 0.0;

//       _currentLocation = LocationModel(
//         id: 'saved_location',
//         name: locationName,
//         city: locationCity,
//         region: locationRegion,
//         latitude: locationLat,
//         longitude: locationLng,
//       );
//       notifyListeners();
//     } catch (e) {
//       print('Error loading saved location: $e');
//     }
//   }

//   Future<void> _saveLocation(LocationModel location) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('location_name', location.name);
//       await prefs.setString('location_city', location.city);
//       await prefs.setString('location_region', location.region);
//       await prefs.setDouble('location_lat', location.latitude);
//       await prefs.setDouble('location_lng', location.longitude);
//     } catch (e) {
//       print('Error saving location: $e');
//     }
//   }

//   Future<LocationModel?> getCurrentLocation() async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           throw Exception('Location permission denied');
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         throw Exception('Location permission permanently denied');
//       }

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       final placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       ).catchError((e) {
//         print('Error fetching placemarks: $e');
//         return <Placemark>[];
//       });

//       if (placemarks.isNotEmpty) {
//         final placemark = placemarks.first;
//         final name = placemark.name ?? 'Unknown Location';
//         final city = placemark.locality ?? placemark.administrativeArea ?? 'Unknown City';
//         final region = _findClosestRegion(
//           placemark.subLocality ?? 'Unknown Area',
//         );

//         final location = LocationModel(
//           id: 'current_location',
//           name: name,
//           city: city,
//           region: region,
//           latitude: position.latitude,
//           longitude: position.longitude,
//         );

//         _currentLocation = location;
//         await _saveLocation(location);

//         _isLoading = false;
//         notifyListeners();
//         return location;
//       }

//       _isLoading = false;
//       notifyListeners();
//       return null;
//     } catch (e) {
//       _isLoading = false;
//       notifyListeners();
//       rethrow;
//     }
//   }

//   String _findClosestRegion(String detectedRegion) {
//     final lowerCaseRegion = detectedRegion.toLowerCase();

//     for (final region in AppConstants.majorRegions) {
//       if (lowerCaseRegion.contains(region.toLowerCase())) {
//         return region;
//       }
//     }

//     return AppConstants.majorRegions.first;
//   }

//   double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
//   }

//   bool isNearby(LocationModel location1, LocationModel location2, double maxDistance) {
//     if (location1.latitude == null || location1.longitude == null ||
//         location2.latitude == null || location2.longitude == null) {
//       return location1.region == location2.region;
//     }

//     return calculateDistance(
//       location1.latitude,
//       location1.longitude,
//       location2.latitude,
//       location2.longitude,
//     ) <= maxDistance;
//   }

//   bool isPostNearby(String postRegion) {
//     if (_currentLocation == null) return false;
//     return postRegion == _currentLocation!.region;
//   }
// }