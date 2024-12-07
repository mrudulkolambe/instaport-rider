// // // ignore_for_file: empty_catches
// import 'package:background_location/background_location.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:instaport_rider/controllers/user.dart';

// class TrackingService extends GetxService {
//   final RiderController riderController = Get.put(RiderController());
//   Rx<Location?> location = Rx<Location?>(null);
//   final _storage = GetStorage();
//   RxString user = RxString("");

//   @override
//   void onInit() {
//     super.onInit();
//     // Listen to changes in the user value and start location tracking if the user is set.
//     ever(user, (String value) {
//       if (value.isNotEmpty) {
//         _startListening();
//       }
//     });
//   }

//   void setUser(String value) {
//     user.value = value;
//     print("Value: $value");
//     if (value.isNotEmpty) {
//       _startListening();
//     }
//   }

//   String isUserSet() {
//     return user.value;
//   }

//   void _startListening() {
//     try {
//       // Set the Android notification for background location tracking.
//       BackgroundLocation.setAndroidNotification(
//         title: 'Background Location',
//         message: 'Location is being tracked in the background',
//         icon: '@drawable/ic_launcher',
//       );

//       // Set the Android configuration for the background location service.
//       BackgroundLocation.setAndroidConfiguration(5000);

//       // Start the location service with a distance filter of 10 meters.
//       BackgroundLocation.startLocationService(distanceFilter: 10);

//       // Listen to location updates.
//       BackgroundLocation.getLocationUpdates((location) async {
//         print("Location ${location.latitude} - ${location.longitude}");
        
//         // Get the Firebase reference for the user.
//         DatabaseReference ref = FirebaseDatabase.instance.ref("rider/${user.value}");
        
//         // Read the token from storage.
//         var token = await _storage.read("token");
        
//         // If the token is available, update the user's location in Firebase.
//         if (token != null) {
//           await ref.update({
//             "latitude": location.latitude,
//             "longitude": location.longitude,
//           });
//           this.location.value = location;
//         }
//       });
//     } catch (e) {
//       // Handle any errors.
//       print("Error in _startListening: $e");
//     }
//   }
// }
