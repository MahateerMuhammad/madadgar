// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:madadgar/config/constants.dart';
// import 'package:madadgar/config/theme.dart';
// import 'package:madadgar/services/location_service.dart';
// import 'package:madadgar/widgets/custom_button.dart';

// class LocationPicker extends StatefulWidget {
//   final String? initialRegion;
//   final Function(String) onRegionSelected;
//   final bool showCurrentLocationButton;
  
//   const LocationPicker({
//     Key? key,
//     this.initialRegion,
//     required this.onRegionSelected,
//     this.showCurrentLocationButton = true,
//   }) : super(key: key);

//   @override
//   State<LocationPicker> createState() => _LocationPickerState();
// }

// class _LocationPickerState extends State<LocationPicker> {
//   late String _selectedRegion;
//   bool _isGettingLocation = false;
  
//   @override
//   void initState() {
//     super.initState();
//     // Initialize with provided region or the first one in the list
//     _selectedRegion = widget.initialRegion ?? AppConstants.majorRegions.first;
//   }
  
//   Future<void> _getCurrentLocation() async {
//     final locationService = Provider.of<LocationService>(context, listen: false);
    
//     setState(() {
//       _isGettingLocation = true;
//     });
    
//     try {
//       final location = await locationService.getCurrentLocation();
      
//       if (location != null) {
//         setState(() {
//           _selectedRegion = location.region;
//         });
        
//         widget.onRegionSelected(_selectedRegion);
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Location set to ${location.region}'),
//             backgroundColor: MadadgarTheme.primaryColor,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error getting your location: ${e.toString()}'),
//           backgroundColor: MadadgarTheme.errorColor,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isGettingLocation = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Region selection dropdown
//         DropdownButtonFormField<String>(
//           value: _selectedRegion,
//           decoration: InputDecoration(
//             labelText: 'Select Region',
//             prefixIcon: const Icon(Icons.location_on),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           items: AppConstants.majorRegions.map((region) {
//             return DropdownMenuItem<String>(
//               value: region,
//               child: Text(region),
//             );
//           }).toList(),
//           onChanged: (value) {
//             if (value != null) {
//               setState(() {
//                 _selectedRegion = value;
//               });
//               widget.onRegionSelected(value);
//             }
//           },
//         ),
        
//         // Current location button
//         if (widget.showCurrentLocationButton) ...[
//           const SizedBox(height: 12),
//           CustomButton(
//             text: 'Use Current Location',
//             onPressed: _getCurrentLocation,
//             type: ButtonType.outline,
//             icon: Icons.my_location,
//             isLoading: _isGettingLocation,
//           ),
//         ],
//       ],
//     );
//   }
// }