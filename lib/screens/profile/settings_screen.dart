// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:madadgar/models/location.dart';

// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({Key? key}) : super(key: key);

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _cityController = TextEditingController(); // Added city field
//   final TextEditingController _regionController = TextEditingController(); // Added region field
//   final TextEditingController _latitudeController = TextEditingController();
//   final TextEditingController _longitudeController = TextEditingController();

//   Future<void> updateUserLocation(String userId) async {
//     try {
//       final name = _nameController.text.trim();
//       final city = _cityController.text.trim(); // Added city field
//       final region = _regionController.text.trim(); // Added region field
//       final latitude = double.tryParse(_latitudeController.text.trim());
//       final longitude = double.tryParse(_longitudeController.text.trim());

//       // Validate inputs
//       if (name.isEmpty || city.isEmpty || region.isEmpty || latitude == null || longitude == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please fill all fields with valid data.')),
//         );
//         return;
//       }

//       final locationData = LocationModel(
//         id: userId,
//         name: name,
//         city: city,
//         region: region,
//         latitude: latitude,
//         longitude: longitude,
//       );

//       await FirebaseFirestore.instance
//           .collection('locations')
//           .doc(userId)
//           .set(locationData.toMap());

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Location updated successfully!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating location: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String userId = 'exampleUserId'; // Replace with actual user ID logic

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Settings'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(labelText: 'Name'),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _cityController,
//                 decoration: const InputDecoration(labelText: 'City'), // Added city field
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _regionController,
//                 decoration: const InputDecoration(labelText: 'Region'), // Added region field
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _latitudeController,
//                 decoration: const InputDecoration(labelText: 'Latitude'),
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _longitudeController,
//                 decoration: const InputDecoration(labelText: 'Longitude'),
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 32),
//               ElevatedButton(
//                 onPressed: () async {
//                   await updateUserLocation(userId);
//                 },
//                 child: const Text('Save Changes'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _cityController.dispose(); // Dispose city controller
//     _regionController.dispose(); // Dispose region controller
//     _latitudeController.dispose();
//     _longitudeController.dispose();
//     super.dispose();
//   }
// }