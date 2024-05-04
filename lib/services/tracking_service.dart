// ignore_for_file: empty_catches

import 'package:background_location/background_location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:instaport_rider/controllers/user.dart';

class TrackingService extends GetxService {
  final RiderController riderController = Get.put(RiderController());
  Rx<Location?> location = Rx<Location?>(null);
  final _storage = GetStorage();
  RxString user = RxString("");

  @override
  void onInit() {
    super.onInit();
    ever(user, (String value) {
      if (value != "") {
        _startListening();
      }
    });
  }

  void setUser(String value) {
    user.value = value;
    print("Value: $value");
    if (value != "") {
      _startListening();
    }
  }

  String isUserSet() {
    return user.value;
  }

  void _startListening() {
    try {
      BackgroundLocation.setAndroidNotification(
        title: 'Background Location',
        message: 'Location is being tracked in the background',
        icon: '@drawable/ic_launcher',
      );
      BackgroundLocation.setAndroidConfiguration(
        5000,
      );

      BackgroundLocation.startLocationService(distanceFilter: 10);

      BackgroundLocation.getLocationUpdates((position) async {
        print("Location ${position.latitude} - ${position.longitude}");
        DatabaseReference ref =
            FirebaseDatabase.instance.ref("rider/${user.value}");
        var token = await _storage.read("token");
        if (token != null) {
          await ref.update({
            "latitude": position.latitude,
            "longitude": position.longitude,
          });
          location.value = position;
        } else {
          // _geolocator.
        }
      });

      // _geolocator
      //     .getPositionStream(
      //   locationSettings: const LocationSettings(
      //     accuracy: LocationAccuracy.bestForNavigation,
      //     distanceFilter: 10,
      //   ),
      // )
      //     .listen((position) async {
      //   print("User: ${user.value}");
        // DatabaseReference ref =
        //     FirebaseDatabase.instance.ref("rider/${user.value}");
        // var token = await _storage.read("token");
        // if (token != null) {
        //   await ref.update({
        //     "latitude": position.latitude,
        //     "longitude": position.longitude,
        //   });
        //   location.value = position;
        // } else {
        //   // _geolocator.
        // }
      // });
    } catch (e) {}
  }
}
