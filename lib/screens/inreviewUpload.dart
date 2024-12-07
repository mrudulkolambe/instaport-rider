import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/models/upload.dart';
import 'package:instaport_rider/screens/inreview.dart';
import 'package:instaport_rider/utils/toast_manager.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class ImageCaptureScreen extends StatefulWidget {
  final String type;
  final String path;
  final String objKey;

  const ImageCaptureScreen(
      {super.key,
      required this.type,
      required this.path,
      required this.objKey});

  @override
  _ImageCaptureScreenState createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  File? _imageFile;
  // final ApiService _apiService = ApiService();
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
  Future<bool> handleSave(key, data) async {
    try {
      var token = await _storage.read("token");
      var headers = {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      };
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
        } else {
          ToastManager.showToast("$key updated");
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

  Future<void> _isAuthed() async {
    final token = await _storage.read("token");
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
    Get.offAll(() => InReview(
          documents: documents,
        ));
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

      final response = await uploadSingleFile(_imageFile!, widget.type);
      print(response!.media.url);
      if (response != null) {
        await handleSave(widget.objKey, {
          "url": response.media.url,
          "status": "pending",
          "type": widget.type
        });
        Fluttertoast.showToast(
          msg: 'Image uploaded successfully!',
          backgroundColor: Colors.green,
        );

        // Cleanup after successful upload
        if (await _imageFile!.exists()) {
          await _imageFile!.delete();
        }

        setState(() {
          _imageFile = null;
        });
        _isAuthed();
      } else {
        throw Exception('Upload failed');
      }
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
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
