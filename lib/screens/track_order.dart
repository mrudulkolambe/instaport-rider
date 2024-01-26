// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instaport_rider/components/address_details.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/address_model.dart';
import 'package:instaport_rider/models/cloudinary_upload.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/screens/home.dart';
import 'package:instaport_rider/services/location_service.dart';
import 'package:instaport_rider/utils/timeformatter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class TrackOrder extends StatefulWidget {
  final Orders data;

  const TrackOrder({super.key, required this.data});

  @override
  State<TrackOrder> createState() => _TrackOrderState();
}

class _TrackOrderState extends State<TrackOrder> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  late GoogleMapController newgooglemapcontroller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylineSet = {};
  bool loading = false;
  List<LatLng> pLineCoordinatedList = [];
  Key _mapKey = UniqueKey();
  AppController appController = Get.put(AppController());
  late StreamSubscription<Position> positionStream;
  int modalState = 0;
  LatLng? CurrentLocation;
  StreamSubscription<Position>? _positionStream;
  BitmapDescriptor riderIcon = BitmapDescriptor.defaultMarker;
  Orders? order;
  List<Column> droplocationslists = [];
  late TabController _tabController;
  final _storage = GetStorage();

  Future<void> _launchUrl(
      LatLng src, LatLng dest, List<Address> droplocations) async {
    String endpoint = "";
    if (droplocations.isEmpty) {
      endpoint =
          "https://www.google.com/maps/dir/?api=1&origin=${src.latitude},${src.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=motorcycle&avoid=tolls&units=imperial&language=en&departure_time=now";
    } else {
      final String waypointsString = droplocations
          .map((address) => '${address.latitude},${address.longitude}')
          .join('|');
      endpoint =
          "https://www.google.com/maps/dir/?api=1&origin=${src.latitude},${src.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=driving&avoid=tolls&units=imperial&language=en&departure_time=now&waypoints=$waypointsString";
    }

    if (!await launchUrl(
      Uri.parse(endpoint),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $endpoint');
    }
  }

  void setcustommarkericon() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      "assets/splash_screen.png",
      mipmaps: true,
    ).then((value) {
      riderIcon = value;
    });
  }

  @override
  void initState() {
    super.initState();
    refresh();
    _tabController = TabController(length: 2, vsync: this);
    // _initializeMap();
    // _getCurrentLocation();
    setcustommarkericon();
    // startForegroundLocationTracking();
    // startBackgroundLocationTracking();
  }

  void handleConfirm(String address) async {
    final token = await _storage.read("token");
    var data = await http.get(Uri.parse("$apiUrl/order/customer/${order!.id}"));
    var orderData = OrderResponse.fromJson(jsonDecode(data.body));
    var filterOrder = orderData.order.orderStatus.where((element) {
      return element.message == address;
    });
    String img = "";
    if (address != "Pickup Started" && filterOrder.isEmpty) {
      img = await getImage();
    }
    if (filterOrder.isEmpty) {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      var request = http.Request(
          'PATCH', Uri.parse('$apiUrl/order/orderstatus/${order!.id}'));
      if (address == "Pickup Started") {
        request.body = json.encode({
          "status": "processing",
          "orderStatus": [
            ...orderData.order.orderStatus.map((e) {
              return e.toJson();
            }).toList(),
            {
              "timestamp": DateTime.now().millisecondsSinceEpoch,
              "message": address,
            }
          ]
        });
      } else if (img != "") {
        request.body = json.encode({
          "status": "processing",
          "orderStatus": [
            ...orderData.order.orderStatus.map((e) {
              return e.toJson();
            }).toList(),
            {
              "timestamp": DateTime.now().millisecondsSinceEpoch,
              "message": address,
              "image": img,
            }
          ]
        });
      } else if (img == "") {
        Get.snackbar("Message", "Image not uploaded yet");
      }
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var json = await response.stream.bytesToString();
        var updatedOrderData = OrderResponse.fromJson(jsonDecode(json));
        setState(() {
          order = updatedOrderData.order;
        });
        Get.back();
        if (address != "Pickup Started") {
          Get.back();
        }
        Get.snackbar("Message", updatedOrderData.message);
      } else {
        Get.back();
        Get.snackbar("Message", response.reasonPhrase!);
      }
    } else {
      Get.back();
      Get.snackbar("Message", "Unable to update");
    }
  }

  void withdrawOrder() async {
    try {
      final token = await _storage.read("token");
      if (order != null && order!.orderStatus.length < 2) {
        var data = await http
            .patch(Uri.parse("$apiUrl/order/withdraw/${order!.id}"), headers: {
          "Authorization": "Bearer $token",
        });
        Get.back();
        var orderData = MessageResponse.fromJson(jsonDecode(data.body));
        Get.snackbar("Message", orderData.message);
      } else {
        Get.snackbar("Message", "Cannot withdraw order");
      }
    } catch (e) {
      print(e);
    }
  }

  void withdrawOrderConfirm() {
    Get.dialog(
        barrierDismissible: false,
        Dialog(
          insetPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 15.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "Confirm",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "You will be charged Rs. 40 for withdrawal",
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                loading
                    ? const SpinKitFadingCircle(
                        color: accentColor,
                        size: 20,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: withdrawOrder,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      width: 2, color: Colors.transparent),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: Text(
                                    "Proceed Withdrawal",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(width: 2, color: accentColor),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
              ],
            ),
          ),
        ));
  }

  Future<bool> requestGalleryPermission() async {
    setState(() {
      // uploading = true;
    });
    if (await Permission.camera.request().isGranted) {
      return true; // Permission already granted
    } else {
      var status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      } else {
        return false;
      }
    }
  }

  Future<String> getImage() async {
    bool permissionGranted = await requestGalleryPermission();
    if (permissionGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        return await uploadToCloudinary(File(image.path));
      } else {
        setState(() {
          // uploading = false;
        });
      }
    } else {
      setState(() {
        // uploading = false;
      });
      openAppSettings();
      Get.snackbar("Error", 'Permission to access gallery denied');
    }
    return "";
  }

  Future<String> uploadToCloudinary(File imageFile) async {
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/dwd2fznsk/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'zkmws48n'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      var data = CloudinaryUpload.fromJson(jsonMap);
      return data.secureUrl;
      // handleSave();
    } else {
      throw "Something went wrong";
    }
  }

  void handleOrderComplete() async {
    final token = await _storage.read("token");
    var data = await http.get(Uri.parse("$apiUrl/order/customer/${order!.id}"));
    var orderData = OrderResponse.fromJson(jsonDecode(data.body));
    if (orderData.order.orderStatus.length ==
        3 + orderData.order.droplocations.length) {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      var request = http.Request(
          'PATCH', Uri.parse('$apiUrl/order/completed/${order!.id}'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var json = await response.stream.bytesToString();
        var updatedOrderData = OrderResponse.fromJson(jsonDecode(json));
        setState(() {
          order = updatedOrderData.order;
        });
        Get.snackbar("Message", updatedOrderData.message);
        Get.to(() => const Home());
      } else {
        Get.back();
        Get.snackbar("Message", response.reasonPhrase!);
      }
    } else {
      Get.back();
      Get.snackbar("Message", "Complete all the dropings first.");
    }
  }

  void handleStatusUpdate() {
    Get.dialog(
        barrierDismissible: false,
        Dialog(
          insetPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 15.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "Complete",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                SingleChildScrollView(
                    child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        handleConfirmStatus("Pickup", order!.pickup.address);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: order!.orderStatus.length >= 2
                              ? accentColor.withOpacity(0.6)
                              : accentColor,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(width: 2, color: Colors.transparent),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        child: Center(
                          child: Text(
                            "Pickup Completed",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    GestureDetector(
                      onTap: () {
                        handleConfirmStatus("Drop", order!.drop.address);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: order!.orderStatus
                                  .where((element) =>
                                      element.message == order!.drop.address)
                                  .isNotEmpty
                              ? accentColor.withOpacity(0.6)
                              : accentColor,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(width: 2, color: Colors.transparent),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        child: Center(
                          child: Text(
                            order!.drop.address,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                    ),
                    ...order!.droplocations.map((e) {
                      return Column(
                        children: [
                          const SizedBox(
                            height: 8,
                          ),
                          GestureDetector(
                            onTap: () {
                              handleConfirmStatus("Drop", e.address);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: order!.orderStatus
                                        .where((element) =>
                                            element.message == e.address)
                                        .isNotEmpty
                                    ? accentColor.withOpacity(0.6)
                                    : accentColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    width: 2, color: Colors.transparent),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              child: Center(
                                child: Text(
                                  e.address,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                )),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: 2, color: accentColor),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Center(
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ));
  }

  void handleConfirmStatus(String task, String address) {
    Get.dialog(
        barrierDismissible: false,
        Dialog(
          insetPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 15.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "Confirm",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                if (task == "start" || task == "order")
                  Row(
                    children: [
                      Text(
                        task == "start"
                            ? "Confirm your start"
                            : "Are you sure you've completed $task?",
                        style: GoogleFonts.poppins(),
                        softWrap: true,
                      ),
                    ],
                  ),
                if (task != "start" && task != 'order')
                  const SizedBox(
                    height: 5,
                  ),
                if (task != "start" && task != 'order')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Address",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        softWrap: true,
                      ),
                      Text(
                        address,
                        style: GoogleFonts.poppins(),
                        softWrap: true,
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 20,
                ),
                loading
                    ? const SpinKitFadingCircle(
                        color: accentColor,
                        size: 20,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => task == "order"
                                  ? handleOrderComplete()
                                  : handleConfirm(address),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      width: 2, color: Colors.transparent),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: Text(
                                    "Yes",
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(width: 2, color: accentColor),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      )
              ],
            ),
          ),
        ));
  }

  void refresh() async {
    var data =
        await http.get(Uri.parse("$apiUrl/order/customer/${widget.data.id}"));
    var orderData = OrderResponse.fromJson(jsonDecode(data.body));
    setState(() {
      order = orderData.order;
      _mapKey = UniqueKey();
      CurrentLocation = LatLng(
        appController.currentposition.value.target.latitude,
        appController.currentposition.value.target.longitude,
      );

      _initializeMap();
      _getCurrentLocation();
      setcustommarkericon();
      var data = List.from(order!.droplocations).asMap().entries.map((e) {
        return Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            const Divider(),
            AddressDetailsScreen(
              address: e.value,
              title: "Drop Point",
              scheduled: order!.delivery_type != "now",
              paymentAddress: order!.payment_address,
              time: order!.time_stamp,
              orderStatus: order!.orderStatus,
              index: e.key + 2,
            type: order!.payment_method
            ),
          ],
        );
      }).toList();
      CurrentLocation = LatLng(
        appController.currentposition.value.target.latitude,
        appController.currentposition.value.target.longitude,
      );
      droplocationslists = data;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _positionStream!.cancel();
    // BackgroundLocation.stopLocationService();
  }

  void _initializeMap() async {
    newgooglemapcontroller = await _mapControllerCompleter.future;
    markersAndPolylines(order!);
  }

  void markersAndPolylines(Orders order) async {
    Set<Marker> funcmarkers = {};
    Set<Polyline> funcpolyline = {};

    Marker pickupmarker = Marker(
      markerId: MarkerId(order.pickup.text),
      infoWindow: const InfoWindow(title: "Pickup"),
      position: LatLng(
        order.pickup.latitude,
        order.pickup.longitude,
      ),
    );

    Marker dropmarker = Marker(
      markerId: MarkerId(order.drop.text),
      infoWindow: const InfoWindow(title: "Drop"),
      position: LatLng(
        order.drop.latitude,
        order.drop.longitude,
      ),
    );

    Set<Marker> defaultMarkerSet = {
      pickupmarker,
      dropmarker,
    };
    var droplocationmarkers = List.from(order.droplocations).map((e) {
      return Marker(
        markerId: MarkerId(e.address),
        infoWindow: const InfoWindow(title: "Drop Point"),
        position: LatLng(
          e.latitude,
          e.longitude,
        ),
      );
    }).toSet();

    funcmarkers = {...defaultMarkerSet, ...droplocationmarkers};
    final directionData = await LocationService().fetchDirections(
      order.pickup.latitude,
      order.pickup.longitude,
      order.drop.latitude,
      order.drop.longitude,
      order.droplocations,
    );
    PolylinePoints pPoints = PolylinePoints();

    List<PointLatLng> decodePolylinePointsResult =
        pPoints.decodePolyline(directionData.e_points!);
    pLineCoordinatedList.clear();

    if (decodePolylinePointsResult.isNotEmpty) {
      for (var pointLatLng in decodePolylinePointsResult) {
        pLineCoordinatedList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    Polyline polyline = Polyline(
      polylineId: const PolylineId("main"),
      color: Colors.black,
      jointType: JointType.round,
      endCap: Cap.roundCap,
      geodesic: true,
      width: 5,
      points: pLineCoordinatedList,
    );
    _polylineSet.clear();
    funcpolyline.add(polyline);

    setState(() {
      // _mapKey = UniqueKey();
      _markers = funcmarkers;
      _polylineSet = funcpolyline;
    });
    repositionGoogleMaps(
      LatLng(order.pickup.latitude, order.pickup.longitude),
      LatLng(order.drop.latitude, order.drop.longitude),
    );
  }

  void _getCurrentLocation() {
    _positionStream = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      forceLocationManager: true,
    )).listen((event) {
      setState(() {
        CurrentLocation = LatLng(
          event.latitude,
          event.longitude,
        );
      });
      // newgooglemapcontroller.animateCamera(
      //   CameraUpdate.newCameraPosition(
      //     CameraPosition(
      //       zoom: 13.5,
      //       target: LatLng(
      //         event.latitude,
      //         event.longitude,
      //       ),
      //     ),
      //   ),
      // );
    });
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void repositionGoogleMaps(LatLng src, LatLng dest) {
    LatLngBounds boundsLatLng;
    if (src.latitude > dest.latitude && src.longitude > dest.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          dest.latitude,
          dest.longitude,
        ),
        northeast: LatLng(
          src.latitude,
          src.longitude,
        ),
      );
    } else if (src.longitude > dest.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          src.latitude,
          dest.longitude,
        ),
        northeast: LatLng(
          dest.latitude,
          src.longitude,
        ),
      );
    } else if (src.latitude > dest.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          dest.latitude,
          src.longitude,
        ),
        northeast: LatLng(
          src.latitude,
          dest.longitude,
        ),
      );
    } else {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          src.latitude,
          src.longitude,
        ),
        northeast: LatLng(
          dest.latitude,
          dest.longitude,
        ),
      );
    }
    newgooglemapcontroller
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));
  }

  double sheetHeight = 350.0; // Initial height of the bottom sheet

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height - sheetHeight,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                sheetHeight = (MediaQuery.of(context).size.height -
                        details.globalPosition.dy)
                    .clamp(100.0, double.infinity);
              });
            },
            child: Column(
              children: <Widget>[
                TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 2.5,
                  enableFeedback: false,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  labelColor: Colors.black,
                  indicatorColor: accentColor,
                  unselectedLabelColor: Colors.black26,
                  tabs: const [
                    Tab(text: 'Details'), // Tab 1: Details
                    Tab(text: 'Breakdown'), // Tab 3: Breakdown
                  ],
                ),
                Expanded(
                  child: SizedBox(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Rs. ${order!.amount.toPrecision(1).toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Weight: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    order!.parcel_weight,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Parcel: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    order!.package,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Customer Name: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    order!.customer.fullname,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Customer No.: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  GestureDetector(
                                    onTap: () => _makePhoneCall(
                                      order!.customer.mobileno,
                                    ),
                                    child: Text(
                                      order!.customer.mobileno,
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Order ID.: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  GestureDetector(
                                    onTap: () => _makePhoneCall(
                                      order!.customer.mobileno,
                                    ),
                                    child: Text(
                                      "#${order!.id.substring(18)}",
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Payment: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    order!.payment_method,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Time: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    readTimestamp(order!.time_stamp),
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              if (order!.orderStatus.length < 2)
                                GestureDetector(
                                  onTap: withdrawOrderConfirm,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: accentColor,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Withdraw Order (-Rs. 40)",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const Divider(),
                              AddressDetailsScreen(
                                  address: order!.pickup,
                                  title: "Pickup",
                                  scheduled: order!.delivery_type != "now",
                                  paymentAddress: order!.payment_address,
                                  time: order!.time_stamp,
                                  orderStatus: order!.orderStatus,
                                  index: 0,
                                  type: order!.payment_method),
                              const SizedBox(
                                height: 15,
                              ),
                              const Divider(),
                              AddressDetailsScreen(
                                address: order!.drop,
                                title: "Drop",
                                scheduled: order!.delivery_type != "now",
                                paymentAddress: order!.payment_address,
                                time: order!.time_stamp,
                                orderStatus: order!.orderStatus,
                                index: 1,
                                type: order!.payment_method,
                              ),
                              ...droplocationslists.map((Column item) {
                                return item;
                              }).toList(),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Instaport Commission",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "- ₹${(order!.amount * (order!.commission / 100)).toPrecision(1).toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 7,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Rider Charge",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "+ ₹${(order!.amount * ((100 - order!.commission) / 100)).toPrecision(1).toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 7,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Parcel Charge",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "₹${(order!.amount).toPrecision(1).toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: CustomAppBar(
          title: "Track #${order == null ? "" : order!.id.substring(18)}",
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Stack(children: [
                SizedBox(
                  // height: MediaQuery.of(context).size.height - 70 - 80 - 65,
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: [
                      if (CurrentLocation != null && order != null)
                        GoogleMap(
                          key: _mapKey,
                          polylines: _polylineSet,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          markers: {
                            if (CurrentLocation != null)
                              Marker(
                                markerId: const MarkerId("Track Marker"),
                                // icon: riderIcon,
                                infoWindow: const InfoWindow(title: "Rider"),
                                position: LatLng(
                                  CurrentLocation!.latitude,
                                  CurrentLocation!.longitude,
                                ),
                              ),
                            ..._markers,
                          },
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              CurrentLocation!.latitude,
                              CurrentLocation!.longitude,
                            ),
                            zoom: 12.14,
                          ),
                          zoomControlsEnabled: false,
                          onMapCreated: (GoogleMapController controller) {
                            if (!_mapControllerCompleter.isCompleted) {
                              _mapControllerCompleter.complete(controller);
                            }
                            newgooglemapcontroller = controller;
                          },
                        ),
                      if (CurrentLocation == null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SpinKitFadingCircle(
                              color: accentColor,
                              size: 50,
                            ),
                            Text(
                              "Setting up the ride!",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                      color: Colors.white,
                                      onPressed: () {
                                        refresh();
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateColor.resolveWith(
                                          (states) => accentColor,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.refresh,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    IconButton(
                                      color: Colors.white,
                                      onPressed: () {
                                        _launchUrl(
                                          LatLng(
                                            order!.pickup.latitude,
                                            order!.pickup.longitude,
                                          ),
                                          LatLng(
                                            order!.drop.latitude,
                                            order!.drop.longitude,
                                          ),
                                          order!.droplocations,
                                        );
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateColor.resolveWith(
                                          (states) => accentColor,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.directions,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    IconButton(
                                      color: Colors.white,
                                      onPressed: () {
                                        repositionGoogleMaps(
                                          LatLng(
                                            order!.pickup.latitude,
                                            order!.pickup.longitude,
                                          ),
                                          LatLng(
                                            order!.drop.latitude,
                                            order!.drop.longitude,
                                          ),
                                        );
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateColor.resolveWith(
                                          (states) => accentColor,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.location_on_rounded,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    IconButton(
                                      color: Colors.white,
                                      onPressed: () {
                                        // _openBottomSheet(context);
                                        setState(() {
                                          sheetHeight = MediaQuery.of(context)
                                                  .size
                                                  .height -
                                              100;
                                        });
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateColor.resolveWith(
                                          (states) => accentColor,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.info,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
                if (order != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          sheetHeight -= details.primaryDelta!;
                          sheetHeight = sheetHeight.clamp(
                              80.0, MediaQuery.of(context).size.height - 100);
                        });
                      },
                      onVerticalDragEnd: (details) {
                        if (sheetHeight < 150.0) {
                          sheetHeight = 80.0;
                        } else if (sheetHeight > 150.0 && sheetHeight < 350) {
                          sheetHeight = 350.0;
                        } else if (sheetHeight > 350) {
                          sheetHeight =
                              MediaQuery.of(context).size.height - 100;
                        }
                      },
                      child: Material(
                        elevation: 10,
                        child: Container(
                          height: sheetHeight,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 30.0,
                                color: Colors.grey[200],
                                child: Center(
                                    child: Container(
                                  height: 3,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                )),
                              ),
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    TabBar(
                                      controller: _tabController,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicatorWeight: 2.5,
                                      enableFeedback: false,
                                      labelStyle: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600),
                                      labelColor: Colors.black,
                                      indicatorColor: accentColor,
                                      unselectedLabelColor: Colors.black26,
                                      tabs: const [
                                        Tab(text: 'Details'), // Tab 1: Details
                                        Tab(
                                            text:
                                                'Breakdown'), // Tab 3: Breakdown
                                      ],
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: [
                                            SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 25),
                                              child: Column(
                                                children: [
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Rs. ${order == null ? "" : order!.amount.toPrecision(1).toString()}",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 28,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 6,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Weight: ",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                        order!.parcel_weight,
                                                        style: GoogleFonts
                                                            .poppins(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 6,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Parcel: ",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                        order!.package,
                                                        style: GoogleFonts
                                                            .poppins(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 6,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Customer Name: ",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                        order!
                                                            .customer.fullname,
                                                        style: GoogleFonts
                                                            .poppins(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 6,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Customer No.: ",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _makePhoneCall(
                                                          order!.customer
                                                              .mobileno,
                                                        ),
                                                        child: Text(
                                                          order!.customer
                                                              .mobileno,
                                                          style: GoogleFonts
                                                              .poppins(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 6,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Order ID.: ",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _makePhoneCall(
                                                          order!.customer
                                                              .mobileno,
                                                        ),
                                                        child: Text(
                                                          "#${order!.id.substring(18)}",
                                                          style: GoogleFonts
                                                              .poppins(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 6,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Payment: ",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                        order!.payment_method,
                                                        style: GoogleFonts
                                                            .poppins(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 6,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Time: ",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                        readTimestamp(
                                                            order!.time_stamp),
                                                        style: GoogleFonts
                                                            .poppins(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  const Divider(),
                                                  AddressDetailsScreen(
                                                      address: order!.pickup,
                                                      title: "Pickup",
                                                      scheduled: order!
                                                              .delivery_type !=
                                                          "now",
                                                      paymentAddress: order!
                                                          .payment_address,
                                                      time: order!.time_stamp,
                                                      orderStatus:
                                                          order!.orderStatus,
                                                      index: 0,
                                                      type: order!
                                                          .payment_method),
                                                  const SizedBox(
                                                    height: 15,
                                                  ),
                                                  const Divider(),
                                                  AddressDetailsScreen(
                                                      address: order!.drop,
                                                      title: "Drop",
                                                      scheduled: order!
                                                              .delivery_type !=
                                                          "now",
                                                      paymentAddress: order!
                                                          .payment_address,
                                                      time: order!.time_stamp,
                                                      orderStatus:
                                                          order!.orderStatus,
                                                      index: 1,
                                                      type: order!
                                                          .payment_method),
                                                  ...droplocationslists
                                                      .map((Column item) {
                                                    return item;
                                                  }).toList(),
                                                  SizedBox(height: 20),
                                                  if (order!
                                                          .orderStatus.length <
                                                      2)
                                                    GestureDetector(
                                                      onTap:
                                                          withdrawOrderConfirm,
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          color: accentColor,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 15,
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            "Withdraw Order (-Rs. 40)",
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(
                                                    height: 70,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 25.0),
                                              child: Column(
                                                children: [
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "Instaport Commission",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        "- ₹${(order!.amount * (order!.commission / 100)).toPrecision(1).toString()}",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 7,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "Rider Charge",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        "+ ₹${(order!.amount * ((100 - order!.commission) / 100)).toPrecision(1).toString()}",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 7,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "Parcel Charge",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        "₹${(order!.amount).toPrecision(1).toString()}",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 55,
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          key: _mapKey,
                          child: GestureDetector(
                            onTap: () {
                              order!.orderStatus.isEmpty
                                  ? handleConfirmStatus(
                                      "start",
                                      "Pickup Started",
                                    )
                                  : order!.orderStatus.length ==
                                          3 + order!.droplocations.length
                                      ? handleConfirmStatus("order", "")
                                      : order!.status == "delivered"
                                          ? ()
                                          : handleStatusUpdate();
                            },
                            child: Container(
                              height: 55,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: order == null
                                    ? accentColor
                                    : order!.status == "delivered"
                                        ? accentColor.withOpacity(0.6)
                                        : accentColor,
                                // borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  order == null
                                      ? "Loading"
                                      : order!.orderStatus.isEmpty
                                          ? "Start Pickup"
                                          : order!.orderStatus.length ==
                                                  3 +
                                                      order!
                                                          .droplocations.length
                                              ? "Complete Order"
                                              : order!.status == "delivered"
                                                  ? "Completed"
                                                  : "I've Reached",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
