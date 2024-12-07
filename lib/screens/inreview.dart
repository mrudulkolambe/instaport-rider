import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/models/upload.dart';
import 'package:instaport_rider/screens/inreviewUpload.dart';
import 'package:instaport_rider/utils/toast_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class InReview extends StatefulWidget {
  const InReview({super.key, required this.documents});
  final List<Map<String, String>> documents;

  @override
  State<InReview> createState() => _InReviewState();
}

class _InReviewState extends State<InReview> {
  var presscount = 0;
  final _storage = GetStorage();
  bool isTimedOut = false;
  Timer? _timer;

  void startTask(key, data) async {
    setState(() {
      isTimedOut = false;
    });
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 15), () {
      setState(() {
        isTimedOut = true;
      });
    });
    print("KEY $key");
    print("data $data");
    var response = await handleSave(
      key,
      data,
    );
    setState(() {
      isTimedOut = false;
    });
    if (response) {
      handleStates(key, "pending");
    } else {
      handleStates(key, "upload");
      ToastManager.showToast("Reupload document");
    }
  }

  List<Map<String, dynamic>> documents = [];
  String aadhaarStatus = "upload";
  String panStatus = "upload";
  String rcStatus = "upload";
  String drivingStatus = "upload";
  String imageStatus = "upload";
  String buttonStatus = "submit";
  String aadhaarReason = "";
  String panReason = "";
  String rcReason = "";
  String drivingReason = "";
  String imageReason = "";

  bool isImageUploaded = false;
  bool isAadhaarUploaded = false;
  bool isPANUploaded = false;
  bool isDrivingLicenseUploaded = false;
  bool isRCBookUploaded = false;

  String getStatus(type) {
    var document = documents.where((doc) {
      return doc["type"] == type;
    });
    return document.first["status"] as String;
  }

  void updateStatusToUpload() {
    setState(() {
      if (imageStatus == "loading") {
        imageStatus = "upload";
      }
      if (aadhaarStatus == "loading") {
        aadhaarStatus = "upload";
      }
      if (panStatus == "loading") {
        panStatus = "upload";
      }
      if (drivingStatus == "loading") {
        drivingStatus = "upload";
      }
      if (rcStatus == "loading") {
        rcStatus = "upload";
      }
    });
  }

  String getReason(type) {
    var document = documents.where((doc) {
      return doc["type"] == type;
    });
    return document.first["reason"] as String;
  }

  @override
  void initState() {
    setState(() {
      documents = widget.documents;
    });
    aadhaarStatus = getStatus("aadhaar");
    panStatus = getStatus("pan");
    rcStatus = getStatus("rc");
    drivingStatus = getStatus("driving");
    imageStatus = getStatus("image");

    aadhaarReason = getReason("aadhaar");
    panReason = getReason("pan");
    rcReason = getReason("rc");
    drivingReason = getReason("driving");
    imageReason = getReason("image");
    _initializeCamera();
    super.initState();
  }

  Future<bool> requestCameraPermission() async {
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

  Future<SingleUploadResponse?> uploadSingleFile(File file, String path) async {
    var request = http.MultipartRequest('POST', Uri.parse("$apiUrl/upload"));
    request.fields.addAll({'path': path});
    request.files.add(await http.MultipartFile.fromPath('files', file.path));
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      final result = await response.stream.bytesToString();
      print(result);
      final data = SingleUploadResponse.fromJson(jsonDecode(result));
      return data;
    } else {
      return null;
    }
  }

  final ImagePicker picker = ImagePicker();

  // Future<SingleUploadResponse?> getImage(path) async {
  //   bool permissionGranted = await requestCameraPermission();
  //   if (permissionGranted) {
  //     // final XFile? image = await picker.pickImage(source: ImageSource.camera);
  //     if (true) {
  //       // File pickedImageFile = File(image.path);
  //       // final data = await uploadSingleFile(pickedImageFile, path);
  //       final data = {
  //         "media": {
  //           "url":
  //               "https://instaport-s3.s3.ap-south-1.amazonaws.com/image/421e0dff-dd51-4380-8827-644c819f64d25082300393085621421.jpg"
  //         }
  //       };
  //       return data as SingleUploadResponse;
  //     } else {
  //       ToastManager.showToast("No image found");
  //       return null;
  //     }
  //   } else {
  //     openAppSettings();
  //     ToastManager.showToast('Permission to access gallery denied');
  //     return null;
  //   }
  // }
  Future<SingleUploadResponse?> getImage(path) async {
    bool permissionGranted = await requestCameraPermission();
    if (!permissionGranted) {
      ToastManager.showToast(
        'Permission not granted',
      );
      openAppSettings();
      return null;
    }
    if (!_isCameraInitialized) {
      ToastManager.showToast(
        'Camera not initialized',
      );
      return null;
    }
    try {
      final XFile photo = await _controller!.takePicture();
      // final Directory appDir =
      //     await path_provider.getApplicationDocumentsDirectory();
      // final String fileName =
      //     '${path}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // final String filePath = '${appDir.path}/$fileName';
      // File(photo.path).copy(filePath);
      final responseForUpload = await uploadSingleFile(File(photo.path), path);
      return responseForUpload;
    } catch (e) {
      ToastManager.showToast('Error capturing image: $e');
    }
    return null;
  }

  final RiderController riderController = Get.put(RiderController());
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        ToastManager.showToast('No cameras found');
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      ToastManager.showToast('Error initializing camera: $e');
    }
  }

  void handleDocuments(key, data) {
    setState(() {
      documents = widget.documents.map((document) {
        if (document.containsKey(key)) {
          document = data;
          return document;
        } else {
          return document;
        }
      }).toList();
    });
  }

  Future<bool> handleSave(key, data) async {
    try {
      handleStates(key, "loading");
      var token = await _storage.read("token");
      var headers = {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      };
      print("data new ${json.encode(data)}");
      print("key new ${json.encode(key)}");
      var request = http.Request('PATCH', Uri.parse('$apiUrl/rider/update'));
      request.body = json.encode({key: data});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var profileData = RiderDataResponse.fromJson(jsonDecode(data));
        riderController.updateRider(profileData.rider);
        if (key == "applied") {
          ToastManager.showToast("Documents submitted");
          handleStates(key, "pending");
        } else {
          ToastManager.showToast("$key updated");
          handleStates(key, "pending");
        }
        return true;
      } else {
        print("ERROR ${response.reasonPhrase!}");
        ToastManager.showToast(response.reasonPhrase!);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void handleStates(key, status) {
    setState(() {
      switch (key) {
        case "image":
          imageStatus = status;
          break;
        case "aadhar_number":
          aadhaarStatus = status;
          break;
        case "pan_number":
          panStatus = status;
          break;
        case "drivinglicense":
          drivingStatus = status;
          break;
        case "rc_book":
          rcStatus = status;
          break;
        default:
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        presscount++;

        if (presscount == 2) {
          exit(0);
        } else {
          var snackBar = const SnackBar(
              content: Text('press another time to exit from app'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Upload Documents",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    InkWell(
                      onTap: () async {
                        if (imageStatus == "upload" ||
                            imageStatus == "reject") {
                          // handleStates("image", "loading");
                          Get.to(() => ImageCaptureScreen(
                                type: "image",
                                path: "image/",
                                objKey: "image",
                              ));
                          // final data = await getImage("image/");
                          // if (data != null) {
                          //   startTask("image", {
                          //     "url": data.media.url,
                          //     "status": "pending",
                          //     "type": "image"
                          //   });
                          // } else {
                          //   updateStatusToUpload();
                          // }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 60,
                        decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Selfie Image *",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (imageStatus == "loading")
                              const Icon(
                                Icons.sync,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (imageStatus == "upload")
                              const Icon(
                                Icons.upload_file,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (imageStatus == "pending")
                              const Icon(
                                Icons.timer_outlined,
                                size: 24,
                                color: Colors.amber,
                              ),
                            if (imageStatus == "reject")
                              const Icon(
                                Icons.warning_outlined,
                                size: 24,
                                color: Colors.red,
                              ),
                            if (imageStatus == "approve")
                              const Icon(
                                Icons.check_circle,
                                size: 24,
                                color: Colors.green,
                              )
                          ],
                        ),
                      ),
                    ),
                    if (imageReason.isNotEmpty)
                      const SizedBox(
                        height: 3,
                      ),
                    if (imageReason.isNotEmpty)
                      Row(
                        children: [
                          Text(imageReason),
                        ],
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    InkWell(
                      onTap: () async {
                        if (aadhaarStatus == "upload" ||
                            aadhaarStatus == "reject") {
                          Get.to(() => ImageCaptureScreen(
                                type: "aadhaar",
                                path: "aadhaar/",
                                objKey: "aadhar_number",
                              ));
                          // handleStates("aadhar_number", "loading");
                          // final data = await getImage("aadhaar/");
                          // if (data != null) {
                          //   startTask("aadhar_number", {
                          //     "url": data.media.url,
                          //     "status": "pending",
                          //     "type": "aadhaar"
                          //   });
                          // } else {
                          //   updateStatusToUpload();
                          // }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 60,
                        decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Aadhaar Card *",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (aadhaarStatus == "loading")
                              const Icon(
                                Icons.sync,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (aadhaarStatus == "upload")
                              const Icon(
                                Icons.upload_file,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (aadhaarStatus == "pending")
                              const Icon(
                                Icons.timer_outlined,
                                size: 24,
                                color: Colors.amber,
                              ),
                            if (aadhaarStatus == "reject")
                              const Icon(
                                Icons.warning_outlined,
                                size: 24,
                                color: Colors.red,
                              ),
                            if (aadhaarStatus == "approve")
                              const Icon(
                                Icons.check_circle,
                                size: 24,
                                color: Colors.green,
                              )
                          ],
                        ),
                      ),
                    ),
                    if (aadhaarReason.isNotEmpty)
                      const SizedBox(
                        height: 3,
                      ),
                    if (aadhaarReason.isNotEmpty)
                      Row(
                        children: [
                          Text(aadhaarReason),
                        ],
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    InkWell(
                      onTap: () async {
                        if (panStatus == "upload" || panStatus == "reject") {
                            Get.to(() => ImageCaptureScreen(
                                type: "pan",
                                path: "pan/",
                                objKey: "pan_number",
                              ));
                          // handleStates("pan_number", "loading");
                          // final data = await getImage("pan/");
                          // if (data != null) {
                          //   startTask("pan_number", {
                          //     "url": data.media.url,
                          //     "status": "pending",
                          //     "type": "pan"
                          //   });
                          // } else {
                          //   updateStatusToUpload();
                          // }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 60,
                        decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "PAN Card *",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (panStatus == "loading")
                              const Icon(
                                Icons.sync,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (panStatus == "upload")
                              const Icon(
                                Icons.upload_file,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (panStatus == "pending")
                              const Icon(
                                Icons.timer_outlined,
                                size: 24,
                                color: Colors.amber,
                              ),
                            if (panStatus == "reject")
                              const Icon(
                                Icons.warning_outlined,
                                size: 24,
                                color: Colors.red,
                              ),
                            if (panStatus == "approve")
                              const Icon(
                                Icons.check_circle,
                                size: 24,
                                color: Colors.green,
                              )
                          ],
                        ),
                      ),
                    ),
                    if (panReason.isNotEmpty)
                      const SizedBox(
                        height: 3,
                      ),
                    if (panReason.isNotEmpty)
                      Row(
                        children: [
                          Text(panReason),
                        ],
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    InkWell(
                      onTap: () async {
                        if (drivingStatus == "upload" ||
                            drivingStatus == "reject") {
                                Get.to(() => ImageCaptureScreen(
                                type: "drivinglicense",
                                path: "drivingLicense/",
                                objKey: "drivinglicense",
                              ));
                          // handleStates("drivinglicense", "loading");
                          // final data = await getImage("drivingLicense/");
                          // if (data != null) {
                          //   startTask("drivinglicense", {
                          //     "url": data.media.url,
                          //     "status": "pending",
                          //     "type": "drivinglicense"
                          //   });
                          // } else {
                          //   updateStatusToUpload();
                          // }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 60,
                        decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Driving License",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (drivingStatus == "loading")
                              const Icon(
                                Icons.sync,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (drivingStatus == "upload")
                              const Icon(
                                Icons.upload_file,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (drivingStatus == "pending")
                              const Icon(
                                Icons.timer_outlined,
                                size: 24,
                                color: Colors.amber,
                              ),
                            if (drivingStatus == "reject")
                              const Icon(
                                Icons.warning_outlined,
                                size: 24,
                                color: Colors.red,
                              ),
                            if (drivingStatus == "approve")
                              const Icon(
                                Icons.check_circle,
                                size: 24,
                                color: Colors.green,
                              )
                          ],
                        ),
                      ),
                    ),
                    if (drivingReason.isNotEmpty)
                      const SizedBox(
                        height: 3,
                      ),
                    if (drivingReason.isNotEmpty)
                      Row(
                        children: [
                          Text(drivingReason),
                        ],
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    InkWell(
                      onTap: () async {
                        if (rcStatus == "upload" || rcStatus == "reject") {
                            Get.to(() => ImageCaptureScreen(
                                type: "rc",
                                path: "rc/",
                                objKey: "rc_book",
                              ));
                          // handleStates("rc_book", "loading");
                          // final data = await getImage("rc/");
                          // if (data != null) {
                          //   startTask("rc_book", {
                          //     "url": data.media.url,
                          //     "status": "pending",
                          //     "type": "rc"
                          //   });
                          // } else {
                          //   updateStatusToUpload();
                          // }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 60,
                        decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "RC Book",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (rcStatus == "loading")
                              const Icon(
                                Icons.sync,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (rcStatus == "upload")
                              const Icon(
                                Icons.upload_file,
                                size: 24,
                                color: Colors.blue,
                              ),
                            if (rcStatus == "pending")
                              const Icon(
                                Icons.timer_outlined,
                                size: 24,
                                color: Colors.amber,
                              ),
                            if (rcStatus == "reject")
                              const Icon(
                                Icons.warning_outlined,
                                size: 24,
                                color: Colors.red,
                              ),
                            if (rcStatus == "approve")
                              const Icon(
                                Icons.check_circle,
                                size: 24,
                                color: Colors.green,
                              )
                          ],
                        ),
                      ),
                    ),
                    if (rcReason.isNotEmpty)
                      const SizedBox(
                        height: 3,
                      ),
                    if (rcReason.isNotEmpty)
                      Row(
                        children: [
                          Text(rcReason),
                        ],
                      ),
                    const SizedBox(
                      height: 30,
                    ),
                    if (riderController.rider.applied)
                      Text(
                        "Your documents are being reviewed!",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (!riderController.rider.applied)
                      GestureDetector(
                        onTap: () {
                          if (aadhaarStatus != "reject" &&
                              aadhaarStatus != "upload" &&
                              panStatus != "reject" &&
                              panStatus != "upload" &&
                              imageStatus != "reject" &&
                              imageStatus != "upload") {
                            handleSave("applied", true);
                          } else {
                            ToastManager.showToast(
                                "Submit all the required documents");
                          }
                        },
                        child: Container(
                          height: 55,
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: accentColor,
                          ),
                          child: Center(
                            child: Text(
                              "Submit",
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
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
            if (imageStatus == "loading" ||
                aadhaarStatus == "loading" ||
                panStatus == "loading" ||
                drivingStatus == "loading" ||
                rcStatus == "loading")
              Stack(
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: GestureDetector(
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      width: MediaQuery.of(context).size.width * 0.95,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 20),
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircularProgressIndicator(
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              color: accentColor,
                            ),
                          ),
                          SizedBox(height: 25),
                          Text(
                            isTimedOut
                                ? "It is taking longer than usual!"
                                : "Loading...",
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                          SizedBox(height: 15),
                          if (isTimedOut)
                            InkWell(
                              onTap: updateStatusToUpload,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.6,
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: accentColor,
                                ),
                                child: Center(
                                  child: Text(
                                    "Reupload",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
          ],
        )),
      ),
    );
  }
}
