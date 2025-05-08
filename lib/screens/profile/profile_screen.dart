// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:madadgar/models/location.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   Future<LocationModel> fetchUserLocation(String userId) async {
//     final doc = await FirebaseFirestore.instance
//         .collection('locations')
//         .doc(userId)
//         .get();
//     return LocationModel.fromFirestore(doc);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String userId = 'exampleUserId'; // Replace with actual user ID logic

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile Screen'),
//       ),
//       body: FutureBuilder<LocationModel>(
//         future: fetchUserLocation(userId),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData) {
//             return const Center(child: Text('No location data found.'));
//           }

//           final location = snapshot.data!;
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Location ID: ${location.id}', style: const TextStyle(fontSize: 16)),
//                 const SizedBox(height: 8),
//                 Text('Name: ${location.name}', style: const TextStyle(fontSize: 16)),
//                 const SizedBox(height: 8),
//                 Text('Latitude: ${location.latitude}', style: const TextStyle(fontSize: 16)),
//                 const SizedBox(height: 8),
//                 Text('Longitude: ${location.longitude}', style: const TextStyle(fontSize: 16)),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }