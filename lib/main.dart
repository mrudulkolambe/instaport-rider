import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
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
import 'package:instaport_rider/screens/verification.dart';
import 'package:instaport_rider/services/tracking_service.dart';
import 'package:instaport_rider/utils/toast_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // final trackingService = Get.put(TrackingService());
  runApp(const MyApp());
}

const apiUrl = "https://instaport-backend-main.vercel.app";
// const apiUrl = "http://192.168.0.101:1000";

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    ToastManager.init(context);
    return GetMaterialApp(
      builder: FToastBuilder(),
      title: 'Instaport Rider',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: accentColor),
        useMaterial3: true,
      ),
      // initialBinding: BindingsBuilder(() {
      //   Get.put<TrackingService>(TrackingService(), permanent: true);
      // }),
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
  // final TrackingService trackingService = Get.put(TrackingService());
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

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _storage.remove("hidden_orders");
    }
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

  bool checkAadharAndPanStatus(List<Map<String, String>> documents) {
    bool aadharApproved = false;
    bool panApproved = false;
    bool imageApproved = false;
    List<String> pendingOrRejected = [];

    // Loop through the list and check the status of Aadhaar and PAN
    for (var document in documents) {
      if (document['type'] == 'image') {
        if (document['status'] == 'approve') {
          imageApproved = true;
        } else {
          pendingOrRejected.add("Aadhaar is ${document['status']}");
        }
      }
      if (document['type'] == 'aadhaar') {
        if (document['status'] == 'approve') {
          aadharApproved = true;
        } else {
          pendingOrRejected.add("Aadhaar is ${document['status']}");
        }
      }

      if (document['type'] == 'pan') {
        if (document['status'] == 'approve') {
          panApproved = true;
        } else {
          pendingOrRejected.add("PAN is ${document['status']}");
        }
      }

      if (document['type'] == 'driving') {
        if (document['status'] != 'approve') {
          pendingOrRejected.add("Driving License is ${document['status']}");
        }
      }

      if (document['type'] == 'rc') {
        if (document['status'] != 'approve') {
          pendingOrRejected.add("RC Book is ${document['status']}");
        }
      }
    }

    // Construct the message with commas and "&" for clarity
    if (pendingOrRejected.isNotEmpty) {
      String message = pendingOrRejected.join(", ");
      if (pendingOrRejected.length > 1) {
        int lastCommaIndex = message.lastIndexOf(", ");
        message =
            message.replaceRange(lastCommaIndex, lastCommaIndex + 2, " & ");
      }
      print(message);
    } else {
      print("All documents are approved.");
    }

    // Return true if both Aadhaar and PAN are approved, otherwise false
    return aadharApproved && panApproved && imageApproved;
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
        riderController.updateRider(userData.rider);
        List<Map<String, String>> documents = [];
        documents.add({
          "type": "aadhaar",
          "status": userData.rider.aadharcard!.status,
          "reason": userData.rider.aadharcard!.reason!,
          "url": userData.rider.aadharcard!.url,
        });
        documents.add({
          "type": "pan",
          "status": userData.rider.pancard!.status,
          "reason": userData.rider.pancard!.reason!,
          "url": userData.rider.pancard!.url,
        });
        documents.add({
          "type": "driving",
          "status": userData.rider.drivinglicense!.status,
          "reason": userData.rider.drivinglicense!.reason!,
          "url": userData.rider.drivinglicense!.url,
        });
        documents.add({
          "type": "rc",
          "status": userData.rider.rc_book!.status,
          "reason": userData.rider.rc_book!.reason!,
          "url": userData.rider.rc_book!.url,
        });
        documents.add({
          "type": "image",
          "status": userData.rider.image!.status,
          "reason": userData.rider.image!.reason!,
          "url": userData.rider.image!.url,
        });
        if (!userData.rider.verified) {
          Get.to(() => const Verification());
        } else if (!userData.rider.approve ||
            !checkAadharAndPanStatus(documents)) {
          Get.to(() => InReview(
                documents: documents,
              ));
        } else if (userData.rider.approve &&
            userData.rider.status == "disabled") {
          Get.to(() => const DisabledScreen());
        } else {
          if (userData.rider.token == token) {
            handleFetchPrice();
            riderController.updateRider(userData.rider);
            // trackingService.setUser(userData.rider.id);
            Get.to(() => const Home());
          } else {
            _storage.remove("token");
            Get.to(() => const Login());
          }
        }
      } catch (e) {
        _storage.remove("token");
        Get.to(() => const Login());
      }
    }
  }

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
