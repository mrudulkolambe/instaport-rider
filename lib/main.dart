import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/controllers/price.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/models/price_model.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/screens/disabled.dart';
import 'package:instaport_rider/screens/home.dart';
import 'package:instaport_rider/screens/inreview.dart';
import 'package:instaport_rider/screens/login.dart';
import 'package:get_storage/get_storage.dart';
import 'package:instaport_rider/services/tracking_service.dart';
import 'package:map_location_picker/google_map_location_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint = (String? message, {int? wrapWidth}) {};
  runApp(const MyApp());
}

const apiUrl = "https://instaport-backend-main.vercel.app";
// const apiUrl = "http://192.168.0.103:1000";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'InstaPort Rider',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: accentColor),
        useMaterial3: true,
      ),
      initialBinding: BindingsBuilder(() {
        Get.put<TrackingService>(TrackingService(), permanent: true);
      }),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AppController appController = Get.put(AppController());
  RiderController riderController = Get.put(RiderController());
  PriceController priceController = Get.put(PriceController());

  void getPermissions() async {
    if (await Permission.location.serviceStatus.isEnabled) {
    } else {}
    var status = await Permission.location.status;
    if (status.isGranted) {
      _getCurrentLocation();
    } else if (status.isDenied) {
      // openAppSettings();
      // Map<Permission, PermissionStatus> status = await [
      await [
        Permission.location,
      ].request();
      if (await Permission.location.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  final _storage = GetStorage();
  @override
  void initState() {
    _isAuthed();
    getPermissions();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _getCurrentLocation() async {
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    appController.updateCurrentPosition(
      CameraPosition(
        target: LatLng(
          position.latitude,
          position.longitude,
        ),
        zoom: 14.14,
      ),
    );
  }

  void handleFetchPrice() async {
    var response = await http.get(Uri.parse("$apiUrl/price/get"));
    final data = PriceManipulationResponse.fromJson(jsonDecode(response.body));
    priceController.updatePrice(data.priceManipulation);
  }

  Future<void> _isAuthed() async {
    final token = await _storage.read("token");
    if (token.toString() == "" || token == null) {
      Get.to(() => const Login());
    } else {
      try {
        final data = await http.get(Uri.parse('$apiUrl/rider/'),
            headers: {'Authorization': 'Bearer $token'});
        final userData = RiderDataResponse.fromJson(jsonDecode(data.body));
        if (!userData.rider.approve) {
          Get.to(() => const InReview());
        } else if (userData.rider.approve &&
            userData.rider.status == "disabled") {
          Get.to(() => const DisabledScreen());
        } else {
          handleFetchPrice();
          riderController.updateRider(userData.rider);
          trackingService.setUser(userData.rider.id);
          Get.to(() => const Home());
        }
      } catch (e) {
        print(e);
        // _storage.remove("token");
        // Get.to(() => const Login());
      }
    }
  }

  final TrackingService trackingService = Get.find<TrackingService>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset("assets/splash_screen.png"),
          ],
        ),
      ),
    );
  }
}
