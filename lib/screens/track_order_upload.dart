import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/address_model.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/models/upload.dart';
import 'package:instaport_rider/screens/track_order.dart';
import 'package:instaport_rider/utils/toast_manager.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:http/http.dart' as http;

class TrackOrderUpload extends StatefulWidget {
  final Orders order;
  final int counter;
  final Function setTimer;
  final Function stopTimer;
  final Function countdownTimer;
  final Function updateOrder;
  final Function refresh;
  final int minute;
  final String address;
  final String addressKey;
  final Address addressObj;
  final String type;

  const TrackOrderUpload({
    super.key,
    required this.order,
    required this.counter,
    required this.setTimer,
    required this.countdownTimer,
    required this.updateOrder,
    required this.refresh,
    required this.stopTimer,
    required this.minute,
    required this.address,
    required this.addressKey,
    required this.addressObj,
    required this.type,
  });

  @override
  State<TrackOrderUpload> createState() => _TrackOrderUploadState();
}

class _TrackOrderUploadState extends State<TrackOrderUpload> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  File? _imageFile;
  bool _isUploading = false;
  bool _isCameraInitialized = false;
  final RiderController riderController = Get.put(RiderController());

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        Fluttertoast.showToast(
          msg: 'No cameras found',
          backgroundColor: Colors.red,
        );
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
      Fluttertoast.showToast(
        msg: 'Error initializing camera: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized) {
      Fluttertoast.showToast(
        msg: 'Camera not initialized',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      final Directory appDir =
          await path_provider.getApplicationDocumentsDirectory();
      final String fileName =
          'captured_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${appDir.path}/$fileName';

      await File(photo.path).copy(filePath);

      setState(() {
        _imageFile = File(filePath);
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error capturing image: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  final _storage = GetStorage();
  void handleConfirm(String address, String key, Address addressObj,
      String type, String url) async {
    final token = await _storage.read("token");
    var data =
        await http.get(Uri.parse("$apiUrl/order/customer/${widget.order.id}"));
    var orderData = OrderResponse.fromJson(jsonDecode(data.body));
    var filterOrder = orderData.order.orderStatus.where((element) {
      return element.message == address;
    });
    String img = "";
    if (address != "Pickup Started" && filterOrder.isEmpty) {
      img = url; // TODO: 001
    }
    if (filterOrder.isEmpty) {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      var request = http.Request(
          'PATCH', Uri.parse('$apiUrl/order/orderstatus/${widget.order.id}'));
      if (address == "Pickup Started") {
        request.body = json.encode({
          "status": "processing",
          "orderStatus": [
            ...orderData.order.orderStatus.map((e) {
              return e.toJson();
            }),
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
          "timer": widget.counter,
          "orderStatus": [
            ...items,
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
          // widget.stopTimer();
          var timerInt = DateTime.now().millisecondsSinceEpoch;
          var timeLimit =
              DateTime.fromMillisecondsSinceEpoch(timerInt + 60 * widget.minute)
                      .millisecondsSinceEpoch +
                  updatedOrderData.order.timer;
          // widget.setTimer(timeLimit - timerInt);
          // widget.countdownTimer();
        } else {
          // widget.stopTimer();
        }
        ToastManager.showToast(updatedOrderData.message);
        // widget.updateOrder(updatedOrderData.order);
        Get.offAll(() => TrackOrder(data: updatedOrderData.order));
        // widget.refresh();
      } else {}
    } else {
      Get.back(closeOverlays: true);
      ToastManager.showToast("Unable to update");
    }
    // while (Get.isDialogOpen! && !Get.isSnackbarOpen) {
    //   Get.back();
    // }
  }

  Future<SingleUploadResponse?> uploadSingleFile(File file, String path) async {
    var request = http.MultipartRequest('POST', Uri.parse("$apiUrl/upload"));
    request.fields['path'] = path;
    request.files.add(await http.MultipartFile.fromPath('files', file.path));

    try {
      final http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final result = await response.stream.bytesToString();
        return SingleUploadResponse.fromJson(jsonDecode(result));
      } else {
        throw Exception(
            'Failed to upload file, Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      Fluttertoast.showToast(
        msg: 'No image selected to upload',
        backgroundColor: Colors.red,
      );
      return;
    }
    setState(() {
      _isUploading = true;
    });
    try {
      if (!await _imageFile!.exists()) {
        throw Exception('Image file not found');
      }
      final response = await uploadSingleFile(_imageFile!, "order/");
      if (response != null) {
        if (await _imageFile!.exists()) {
          await _imageFile!.delete();
        }
        setState(() {
          _imageFile = null;
        });
        handleConfirm(
          widget.address,
          widget.addressKey,
          widget.addressObj,
          widget.type,
          response.media.url,
        );
        Fluttertoast.showToast(
          msg: 'Image uploaded successfully!',
          backgroundColor: Colors.green,
        );
      } else {
        throw Exception('Upload failed');
      }
      // TODO: ISAUTHED
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error uploading image: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Instaport',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _imageFile == null
                ? Container(
                    margin:
                        const EdgeInsets.all(0).copyWith(left: 10, right: 10),
                    height: 400,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CameraPreview(_controller!),
                    ),
                  )
                : Container(
                    margin:
                        const EdgeInsets.all(0).copyWith(left: 10, right: 10),
                    height: 400,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _imageFile = null;
                });
              },
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.red,
                  ),
                  child: const Text("Retake Image"),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.transparent,
        height: 80,
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _isUploading ? null : _captureImage,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _isUploading ? Colors.grey : Colors.yellow,
                  ),
                  child: const Center(
                    child: Text(
                      'Capture',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: _isUploading ? null : _uploadImage,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _isUploading ? Colors.grey : Colors.yellow,
                  ),
                  child: Center(
                    child: _isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Upload',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
