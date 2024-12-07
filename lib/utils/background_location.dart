// import 'package:background_location/background_location.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:get/get.dart';

// class LocationController extends GetxController {
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
//   var isFetching = false.obs;
//   late String riderId;

//   // Initialize the rider ID
//   void initialize(String id) {
//     riderId = id;
//   }

//   // Start fetching location
//   Future<void> startFetchingLocation() async {
//     if (isFetching.value) return;

//     isFetching.value = true;
//     await BackgroundLocation.setAndroidNotification(
//       title: 'Background service is running',
//       message: 'Background location in progress',
//       icon: '@mipmap/ic_launcher',
//     );
//     BackgroundLocation.setAndroidConfiguration(1000);
//     await BackgroundLocation.startLocationService();
//     BackgroundLocation.getLocationUpdates((location) async {
//       final lat = location.latitude;
//       final lng = location.longitude;

//       // Update location in Firebase Realtime Database
//       print("location: $lat $lng");
//       // await _database
//       //     .ref("riders/$riderId/location")
//       //     .set({'latitude': lat, 'longitude': lng});
//     });
//   }

//   // Stop fetching location
//   Future<void> stopFetchingLocation() async {
//     print("stopped");
//     if (!isFetching.value) return;

//     isFetching.value = false;
//     await BackgroundLocation.stopLocationService();
//   }

//   @override
//   void onClose() {
//     // Ensure location service is stopped when controller is disposed
//     stopFetchingLocation();
//     super.onClose();
//   }
// }
