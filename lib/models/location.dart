import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String id;
  final String name;
  final String city; // Add this field
  final String region; // Add this field
  final double latitude;
  final double longitude;

  LocationModel({
    required this.id,
    required this.name,
    required this.city, // Add this field
    required this.region, // Add this field
    required this.latitude,
    required this.longitude,
  });

  // Factory method to create a LocationModel from Firestore data
  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel(
      id: doc.id,
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      region: data['region'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
    );
  }

  // Convert LocationModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}