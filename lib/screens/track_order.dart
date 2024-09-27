// ignore_for_file: deprecated_member_use, non_constant_identifier_names, unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/firebase_messaging/firebase_messaging.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/address_model.dart';
import 'package:instaport_rider/models/cloudinary_upload.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/models/places_model.dart';
import 'package:instaport_rider/models/price_model.dart';
import 'package:instaport_rider/models/upload.dart';
import 'package:instaport_rider/screens/home.dart';
import 'package:instaport_rider/services/location_service.dart';
import 'package:instaport_rider/utils/timeformatter.dart';
import 'package:instaport_rider/utils/toast_manager.dart';
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
  PriceManipulation? price;
  StreamSubscription<Position>? _positionStream;
  BitmapDescriptor riderIcon = BitmapDescriptor.defaultMarker;
  Orders? order;
  OnlyDetails? realtime;
  List<Column> droplocationslists = [];
  late TabController _tabController;
  final _storage = GetStorage();
  Timer? _timer;
  StreamSubscription<DatabaseEvent>? _databaseListener;
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  final int minute = 60000;
  String timeOfTimer = "";

  Future<void> _launchUrl(
      LatLng src, LatLng dest, List<Address> droplocations) async {
    String endpoint = "";
    if (droplocations.isEmpty) {
      endpoint =
          "https://www.google.com/maps/dir/?api=1&origin=${src.latitude},${src.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=motorcycle&avoid=tolls&units=imperial&language=en&departure_time=now";
    } else {
      final List<LatLng> dropArr = [];
      dropArr.add(dest);
      if (droplocations.length > 1) {
        for (var i = 0; i < droplocations.length - 2; i++) {
          dropArr.add(
              LatLng(droplocations[i].latitude, droplocations[i].longitude));
        }
      }
      final String waypointsString = dropArr
          .map((address) => '${address.latitude},${address.longitude}')
          .join('|');
      endpoint =
          "https://www.google.com/maps/dir/?api=1&origin=${src.latitude},${src.longitude}&destination=${droplocations.last.latitude},${droplocations.last.longitude}&travelmode=driving&avoid=tolls&units=imperial&language=en&departure_time=now&waypoints=$waypointsString";
    }

    if (!await launchUrl(
      Uri.parse(endpoint),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $endpoint');
    }
  }

  @override
  void initState() {
    super.initState();
    handlePriceFetch();
    refreshMain();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      refresh();
    });
    _initializeMap();
    _tabController = TabController(length: 2, vsync: this);
  }

  int _counter = 0;
  late Timer _countdown;

  void countdownTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (Timer timer) {
      try {
        setState(() {
          _counter = _counter - 1000;
          timeOfTimer = _counter < 0
              ? "-${formatMilliseconds(_counter.abs())}"
              : formatMilliseconds(_counter.abs());
        });
      } catch (e) {}
    });
  }

  void stopTimer() {
    _timer!.cancel();
  }

  void handleConfirm(
      String address, String key, Address addressObj, String type) async {
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
        var items = orderData.order.orderStatus.map((e) {
          return e.toJson();
        });
        request.body = json.encode({
          "status": "processing",
          "timer": _counter,
          "orderStatus": [
            ...items.toList(),
            {
              "timestamp": DateTime.now().millisecondsSinceEpoch,
              "message": address,
              "image": img,
              "key": key,
            }
          ]
        });
      } else if (img == "") {
        ToastManager.showToast("Image not uploaded yet");
      }
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var json = await response.stream.bytesToString();
        var updatedOrderData = OrderResponse.fromJson(jsonDecode(json));
        if (updatedOrderData.order.orderStatus.isEmpty) {
        } else if (updatedOrderData.order.orderStatus.isNotEmpty &&
            updatedOrderData.order.orderStatus.length == 1) {
          // stopTimer();
          // var timeLimit = DateTime.fromMillisecondsSinceEpoch(
          //         updatedOrderData.order.timer + 45 * minute)
          //     .millisecondsSinceEpoch;
          // setState(() {
          //   _counter = timeLimit - updatedOrderData.order.time_stamp;
          // });
          // countdownTimer();
        } else if (updatedOrderData.order.status == "processing" &&
            updatedOrderData.order.orderStatus.length !=
                3 + updatedOrderData.order.droplocations.length) {
          stopTimer();
          var timerInt = DateTime.now().millisecondsSinceEpoch;
          var timeLimit =
              DateTime.fromMillisecondsSinceEpoch(timerInt + 60 * minute)
                      .millisecondsSinceEpoch +
                  updatedOrderData.order.timer;
          setState(() {
            _counter = timeLimit - timerInt;
          });
          countdownTimer();
        } else {
          stopTimer();
        }
        ToastManager.showToast(updatedOrderData.message);
        setState(() {
          order = updatedOrderData.order;
        });
        refresh();
      } else {}
    } else {
      Get.back(closeOverlays: true);
      ToastManager.showToast("Unable to update");
    }
    while (Get.isDialogOpen! && !Get.isSnackbarOpen) {
      Get.back();
    }
  }

  void withdrawOrder(String type) async {
    try {
      final token = await _storage.read("token");
      if (order != null && order!.orderStatus.length < 2) {
        var data = await http.patch(
            Uri.parse("$apiUrl/order/withdraw/${order!.id}/$type"),
            headers: {
              "Authorization": "Bearer $token",
            });
        FirebaseDatabase.instance
            .ref('/orders/${order!.id}')
            .update({"modified": ""});
        while (Get.isDialogOpen! && !Get.isSnackbarOpen) {
          Get.back();
        }
        var orderData = MessageResponse.fromJson(jsonDecode(data.body));
        FirebaseMessagingAPI().localNotificationsApp(RemoteNotification(
            title: "Order Withdrawn",
            body:
                "Order #${order!.id.substring(18)} has been successfully withdrawn!"));
        Get.to(() => const Home());
        ToastManager.showToast(orderData.message);
      } else {
        ToastManager.showToast("Cannot withdraw order");
      }
    } catch (e) {
      // print(e);
    }
  }

  void withdrawOrderConfirm(String type) {
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
                      type != "update"
                          ? "You will be charged Rs. ${price == null ? 40 : price!.withdrawalCharges} for withdrawal"
                          : "Are you sure you want to withdraw the order?",
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => withdrawOrder(type),
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentColor,
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
                              "Proceed",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
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
                                fontSize: 14,
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
        File pickedImageFile = File(image.path);
        int sizeInBytes = await pickedImageFile.length();
        double sizeInMB = sizeInBytes / (1024 * 1024);
        if (sizeInMB <= 10.0) {
          final imgUrl = await uploadSingleFile(
              pickedImageFile, "${widget.data.id}/track/");
          return imgUrl as String;
        } else {
          ToastManager.showToast("Size should be less than 10MB");
        }
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
      ToastManager.showToast('Permission to access gallery denied');
    }
    return "";
  }

  void displayUploading() {
    Get.dialog(
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
              const CircularProgressIndicator(
                color: accentColor,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Image Is Uploading",
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      useSafeArea: true,
    );
  }

  Future<String?> uploadSingleFile(File file, String path) async {
    var request = http.MultipartRequest('POST', Uri.parse("$apiUrl/upload"));
    request.fields.addAll({'path': path});
    request.files.add(await http.MultipartFile.fromPath('files', file.path));
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      final result = await response.stream.bytesToString();
      final data = SingleUploadResponse.fromJson(jsonDecode(result));
      return data.media.url;
    } else {
      return null;
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
        if (_counter < 0) {
          FirebaseMessagingAPI().localNotificationsApp(RemoteNotification(
              title: "Order Completed",
              body: "The order was not delivered on time."));
        }
        setState(() {
          order = updatedOrderData.order;
        });
        ToastManager.showToast(updatedOrderData.message);
        Get.to(() => const Home());
      } else {
        Get.back();
        ToastManager.showToast(response.reasonPhrase!);
      }
    } else {
      Get.back();
      ToastManager.showToast("Complete all the dropings first.");
    }
  }

  void handleStatusUpdate() async {
    if (order!.orderStatus.length == 1) {
      var posi = await _getCurrentLocationSingle();
      var distance = await LocationService().fetchDistance(
          LatLng(posi.latitude, posi.longitude),
          LatLng(order!.pickup.latitude, order!.pickup.longitude));
      if (distance <= 2500) {
        handleConfirmStatus("Pickup", order!.pickup, "pick");
      } else {
        ToastManager.showToast(
            "Your location should be in the range of 2.5km from the location");
      }
    } else if (order!.orderStatus.length == 2 && order!.droplocations.isEmpty) {
      var posi = await _getCurrentLocationSingle();
      var distance = await LocationService().fetchDistance(
          LatLng(posi.latitude, posi.longitude),
          LatLng(order!.drop.latitude, order!.drop.longitude));
      if (distance <= 2500) {
        handleConfirmStatus("Drop", order!.drop, "drop");
      } else {
        ToastManager.showToast(
            "Your location should be in the range of 2.5km from the location");
      }
    } else {
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
                    if (order!.orderStatus
                        .where((element) => element.key == order!.drop.key)
                        .isEmpty)
                      GestureDetector(
                        onTap: () async {
                          var posi = await _getCurrentLocationSingle();
                          var distance = await LocationService().fetchDistance(
                              LatLng(posi.latitude, posi.longitude),
                              LatLng(
                                  order!.drop.latitude, order!.drop.longitude));
                          if (distance <= 2500) {
                            handleConfirmStatus("Drop", order!.drop, "drop");
                          } else {
                            ToastManager.showToast(
                                "Your location should be in the range of 2.5km from the location");
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: order!.orderStatus
                                    .where((element) =>
                                        element.key == order!.drop.key)
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
                          if (order!.orderStatus
                              .where((element) => element.key == e.key)
                              .isEmpty)
                            GestureDetector(
                              onTap: () {
                                handleConfirmStatus("Drop", e, "drop");
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: order!.orderStatus
                                          .where(
                                              (element) => element.key == e.key)
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
        ),
      );
    }
  }

  void handleConfirmStatus(String task, Address address, String type) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    mainAxisAlignment: MainAxisAlignment.start,
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
                      Row(
                        children: [
                          Text(
                            "Address",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                            softWrap: true,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            address.address,
                            style: GoogleFonts.poppins(),
                            softWrap: true,
                          ),
                        ],
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
                                  : handleConfirm(address.address, address.key,
                                      address, type),
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

  void handlePriceFetch() async {
    var response = await http.get(Uri.parse("$apiUrl/price/get"));
    final data = PriceManipulationResponse.fromJson(jsonDecode(response.body));
    setState(() {
      price = data.priceManipulation;
    });
  }

  void refreshMain() async {
    var data =
        await http.get(Uri.parse("$apiUrl/order/customer/${widget.data.id}"));
    var orderData = OrderResponse.fromJson(jsonDecode(data.body));
    if (orderData.order.status == "processing") {
      int latestTime = DateTime.now().millisecondsSinceEpoch;
      if (orderData.order.orderStatus.length < 2 &&
          orderData.order.status == "processing") {
        var timeLimit = DateTime.fromMillisecondsSinceEpoch(
                orderData.order.time_stamp + 45 * minute)
            .millisecondsSinceEpoch;
        setState(() {
          _counter = timeLimit - latestTime;
        });
        countdownTimer();
      } else if (orderData.order.orderStatus.length > 1 &&
          orderData.order.status == "processing" &&
          orderData.order.orderStatus.length !=
              3 + orderData.order.droplocations.length) {
        var timeLimit = DateTime.fromMillisecondsSinceEpoch(
                    orderData.order.time_stamp + 60 * minute)
                .millisecondsSinceEpoch +
            _counter;
        setState(() {
          _counter = timeLimit - latestTime;
        });
        countdownTimer();
      }
    }
    setState(() {
      order = orderData.order;
      _mapKey = UniqueKey();
      CurrentLocation = LatLng(
        appController.currentposition.value.target.latitude,
        appController.currentposition.value.target.longitude,
      );

      _getCurrentLocation();
      var data = List.from(order!.droplocations).asMap().entries.map((e) {
        return Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            const Divider(),
            AddressDetailsScreen(
              key: Key((e.key + 2).toString()),
              address: e.value,
              title: "Drop Point",
              scheduled: order!.delivery_type != "now",
              paymentAddress: order!.payment_address,
              time: order!.time_stamp,
              orderStatus: order!.orderStatus,
              index: e.key + 2,
              type: order!.payment_method,
              amount: order!.amount,
              status: order!.status,
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
    if (orderData.order.status != "delivered") {
      _databaseListener = ref
          .child('orders/${widget.data.id}')
          .onValue
          .listen((DatabaseEvent event) async {
        final data = event.snapshot.value;
        final dynamic snapshotValue = json.encode(data);
        print(jsonDecode(snapshotValue));
        if (snapshotValue != null) {
          while (Get.isDialogOpen! && !Get.isSnackbarOpen) {
            Get.back();
          }
          final data = RealtimeOrder.fromJson(jsonDecode(snapshotValue));
          var updatedData = await http
              .get(Uri.parse("$apiUrl/order/customer/${widget.data.id}"));
          var orderData =
              OrderResponse.fromJson(jsonDecode(updatedData.body)).order;
          setState(() {
            var modData =
                List.from(orderData.droplocations).asMap().entries.map((e) {
              return Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  const Divider(),
                  AddressDetailsScreen(
                    key: Key((e.key + 2).toString()),
                    address: e.value,
                    title: "Drop Point",
                    scheduled: orderData.delivery_type != "now",
                    paymentAddress: orderData.payment_address,
                    time: orderData.time_stamp,
                    orderStatus: orderData.orderStatus,
                    index: e.key + 2,
                    type: orderData.payment_method,
                    amount: orderData.amount,
                    status: orderData.status,
                  ),
                ],
              );
            }).toList();
            droplocationslists = modData;
          });
          if (data.modified == "data") {
            print(data.modified);
            // FirebaseMessagingAPI().localNotificationsApp(RemoteNotification(title: "Order Updated", body: "Order #${widget.data.id.substring(18)} has been updated by the customer!"));
            Get.dialog(
              WillPopScope(
                onWillPop: () async {
                  return false;
                },
                child: Dialog.fullscreen(
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Rs. ${(orderData.amount * ((100 - orderData.commission) / 100)).toPrecision(2).toString()}",
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "#${orderData.id.substring(18)}",
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
                              "Weight: ",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Text(
                              orderData.parcel_weight,
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
                              orderData.package,
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
                              orderData.customer.fullname,
                              style: GoogleFonts.poppins(),
                            ),
                          ],
                        ),
                        if (orderData.status != "delivered")
                          const SizedBox(
                            height: 6,
                          ),
                        if (orderData.status != "delivered")
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
                                  orderData.customer.mobileno,
                                ),
                                child: Text(
                                  orderData.customer.mobileno,
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
                              orderData.payment_method,
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
                              readTimestamp(orderData.time_stamp),
                              style: GoogleFonts.poppins(),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Divider(),
                        AddressDetailsScreen(
                          address: orderData.pickup,
                          title: "Pickup",
                          scheduled: orderData.delivery_type != "now",
                          paymentAddress: orderData.payment_address,
                          time: orderData.time_stamp,
                          orderStatus: orderData.orderStatus,
                          index: 0,
                          amount: orderData.amount,
                          type: orderData.payment_method,
                          status: orderData.status,
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        const Divider(),
                        AddressDetailsScreen(
                          address: orderData.drop,
                          title: "Drop",
                          scheduled: orderData.delivery_type != "now",
                          paymentAddress: orderData.payment_address,
                          time: orderData.time_stamp,
                          orderStatus: orderData.orderStatus,
                          index: 1,
                          type: orderData.payment_method,
                          amount: orderData.amount,
                          status: orderData.status,
                        ),
                        ...droplocationslists.map((Column item) {
                          return item;
                        }).toList(),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                FirebaseDatabase.instance
                                    .ref('/orders/${orderData.id}')
                                    .update({"modified": ""}).then((value) {
                                  markersAndPolylines(orderData);
                                  if (Get.isDialogOpen! &&
                                      !Get.isSnackbarOpen) {
                                    Get.back();
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 15,
                                ),
                                child: Center(
                                  child: Text(
                                    "Accept",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
                                if (orderData.orderStatus.length >= 2) {
                                  ToastManager.showToast(
                                      "You cannot withdraw the order if the item is picked!");
                                } else {
                                  withdrawOrderConfirm("update");
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 15,
                                ),
                                child: Center(
                                  child: Text(
                                    "Withdraw",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              barrierDismissible: false,
            );
          } else if (data.modified == "cancel") {
            // FirebaseMessagingAPI().localNotificationsApp(RemoteNotification(title: "Order Cancelled", body: "Order #${widget.data.id.substring(18)} has been cancelled by the customer!"));
            Get.dialog(
              Dialog(
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  height: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            "Cancel",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            "Your order has been cancelled by the customer",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          FirebaseDatabase.instance
                              .ref('/orders/${orderData.id}')
                              .update({"modified": ""}).then((value) {
                            Get.to(() => const Home());
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 15,
                          ),
                          child: Center(
                            child: Text(
                              "Okay",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              barrierDismissible: false,
            );
          }
          // setState(() {
          //   realtime = data.order;
          // });
        }
      });
    } else {
      print("this is not correct");
    }
  }

  void refresh() async {
    try {
      var data =
          await http.get(Uri.parse("$apiUrl/order/customer/${widget.data.id}"));
      var orderData = OrderResponse.fromJson(jsonDecode(data.body));
      setState(() {
        order = orderData.order;
        var data = List.from(order!.droplocations).asMap().entries.map((e) {
          return Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              const Divider(),
              AddressDetailsScreen(
                key: Key((e.key + 2).toString()),
                address: e.value,
                title: "Drop Point",
                scheduled: order!.delivery_type != "now",
                paymentAddress: order!.payment_address,
                time: order!.time_stamp,
                orderStatus: order!.orderStatus,
                index: e.key + 2,
                type: order!.payment_method,
                amount: order!.amount,
                status: order!.status,
              ),
            ],
          );
        }).toList();
        droplocationslists = data;
      });
    } catch (e) {
      // throw Exception("Error");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream!.cancel();
    newgooglemapcontroller.dispose();
    if (order!.rider != null) {
      ref.onValue.drain();
      if (_databaseListener != null) {
        _databaseListener!.cancel();
      }
    }
    super.dispose();
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
        appController.updateCurrentPosition(
            CameraPosition(target: LatLng(event.latitude, event.longitude)));
      });
    });
  }

  Future<Position> _getCurrentLocationSingle() async {
    var posi = await Geolocator.getCurrentPosition();
    appController.updateCurrentPosition(
        CameraPosition(target: LatLng(posi.latitude, posi.longitude)));
    return posi;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   toolbarHeight: 60,
      //   surfaceTintColor: Colors.white,
      //   automaticallyImplyLeading: false,
      //   backgroundColor: Colors.white,
      //   title: CustomAppBar(
      //     title: "Track #${order == null ? "" : order!.id.substring(18)}",
      //   ),
      // ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Stack(children: [
                SizedBox(
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
                              "Loading",
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
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
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
                                      width: 5,
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
                                      width: 5,
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
                                      width: 5,
                                    ),
                                    IconButton(
                                      color: Colors.white,
                                      onPressed: () {
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
                              order != null &&
                                      order!.orderStatus.length !=
                                          3 + order!.droplocations.length &&
                                      order!.status == "processing"
                                  ? 145.0
                                  : 80,
                              MediaQuery.of(context).size.height - 35);
                        });
                      },
                      onVerticalDragEnd: (details) {
                        if (sheetHeight < 230.0) {
                          sheetHeight = order != null &&
                                  order!.orderStatus.length !=
                                      3 + order!.droplocations.length &&
                                  order!.status == "processing"
                              ? 145.0
                              : 80;
                        } else if (sheetHeight > 230.0 && sheetHeight < 350) {
                          sheetHeight = 350.0;
                        } else if (sheetHeight > 350) {
                          sheetHeight = MediaQuery.of(context).size.height - 35;
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
                                        Tab(
                                          text: 'Details',
                                        ),
                                        Tab(
                                          text: 'Breakdown',
                                        ),
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
                                                horizontal: 25,
                                              ),
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
                                                        "Rs. ${(order!.amount * ((100 - order!.commission) / 100)).toPrecision(2).toString()}",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 28,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        "#${order!.id.substring(18)}",
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
                                                  if (order!.status !=
                                                      "delivered")
                                                    const SizedBox(
                                                      height: 6,
                                                    ),
                                                  if (order!.status !=
                                                      "delivered")
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Customer No.: ",
                                                          style: GoogleFonts
                                                              .poppins(
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
                                                    scheduled:
                                                        order!.delivery_type !=
                                                            "now",
                                                    paymentAddress:
                                                        order!.payment_address,
                                                    time: order!.time_stamp,
                                                    orderStatus:
                                                        order!.orderStatus,
                                                    index: 0,
                                                    amount: order!.amount,
                                                    type: order!.payment_method,
                                                    status: order!.status,
                                                  ),
                                                  const SizedBox(
                                                    height: 15,
                                                  ),
                                                  const Divider(),
                                                  AddressDetailsScreen(
                                                    address: order!.drop,
                                                    title: "Drop",
                                                    scheduled:
                                                        order!.delivery_type !=
                                                            "now",
                                                    paymentAddress:
                                                        order!.payment_address,
                                                    time: order!.time_stamp,
                                                    orderStatus:
                                                        order!.orderStatus,
                                                    index: 1,
                                                    type: order!.payment_method,
                                                    amount: order!.amount,
                                                    status: order!.status,
                                                  ),
                                                  ...droplocationslists
                                                      .map((Column item) {
                                                    return item;
                                                  }).toList(),
                                                  const SizedBox(height: 20),
                                                  if (order!
                                                          .orderStatus.length <
                                                      2)
                                                    GestureDetector(
                                                      onTap: () =>
                                                          withdrawOrderConfirm(
                                                              "other"),
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
                                                            "Withdraw Order (-Rs. ${price == null ? 40 : price!.withdrawalCharges})",
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
                                                    height: 130,
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
                                                  if (order!.payment_method ==
                                                      "cod")
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          "Instaport Commission",
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          "- ₹${(order!.amount * (order!.commission / 100)).toPrecision(1).toString()}",
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  if (order!.payment_method ==
                                                      "cod")
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
                  child: Column(
                    children: [
                      if (order != null &&
                          order!.orderStatus.length !=
                              3 + order!.droplocations.length &&
                          order!.status == "processing")
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(
                                width: 1,
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ),
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                              child: Text(
                            timeOfTimer,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: _counter < 0 ? Colors.red : Colors.black,
                            ),
                          )),
                        ),
                      Container(
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
                                          Address(
                                              text: "",
                                              latitude: 0.0,
                                              longitude: 0.0,
                                              building_and_flat: "",
                                              floor_and_wing: "",
                                              instructions: "",
                                              phone_number: "",
                                              address: "Pickup Started",
                                              key: "pickup started",
                                              name: ""),
                                          "start")
                                      : order!.orderStatus.length ==
                                              3 + order!.droplocations.length
                                          ? handleConfirmStatus(
                                              "order",
                                              Address(
                                                  text: "",
                                                  latitude: 0.0,
                                                  longitude: 0.0,
                                                  building_and_flat: "",
                                                  floor_and_wing: "",
                                                  instructions: "",
                                                  phone_number: "",
                                                  address: "Order Completed",
                                                  key: "completed",
                                                  name: ""),
                                              "complete")
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
                                              : order!.orderStatus.length == 1
                                                  ? "Parcel Picked Up"
                                                  : order!.orderStatus.length ==
                                                          3 +
                                                              order!
                                                                  .droplocations
                                                                  .length
                                                      ? "Complete Order"
                                                      : order!.status ==
                                                              "delivered"
                                                          ? "Completed"
                                                          : "Parcel Dropped",
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
                    ],
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
