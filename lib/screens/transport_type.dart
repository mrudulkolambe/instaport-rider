// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/models/cloudinary_upload.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportType extends StatefulWidget {
  const TransportType({super.key});

  @override
  State<TransportType> createState() => _TransportTypeState();
}

class _TransportTypeState extends State<TransportType> {
  final _storage = GetStorage();
  RiderController riderController = Get.put(RiderController());
  bool loading = false;
  String vehicle = "scooty";
  String drivinglicense = "";

  @override
  void initState() {
    super.initState();
    handlePrefetch();
  }

  Future<bool> requestGalleryPermission() async {
    setState(() {
      loading = true;
    });
    if (await Permission.storage.request().isGranted) {
      return true;
    } else {
      var status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else {
        return false;
      }
    }
  }

  void _launchURL(String drivinglicense) async {
    if (drivinglicense.isNotEmpty &&
        !await launchUrl(
          Uri.parse(drivinglicense),
          mode: LaunchMode.platformDefault,
        )) {
      throw Exception('Could not launch $drivinglicense');
    }
  }

  Future<void> uploadToCloudinary(File imageFile) async {
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/dwd2fznsk/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'pmoqxm8k'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      var data = CloudinaryUpload.fromJson(jsonMap);
      setState(() {
        drivinglicense = data.secureUrl;
      });
      handleSave();
      Get.snackbar("Message", 'Driving license updated successfully!');
    }
  }

  Future<void> getImage() async {
    bool permissionGranted = await requestGalleryPermission();
    if (permissionGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        uploadToCloudinary(File(image.path));
      } else {
        setState(() {
          loading = false;
        });
      }
    } else {
      setState(() {
        loading = false;
      });
      openAppSettings();
      Get.snackbar("Error", 'Permission to access gallery denied');
    }
    return;
  }

  void handlePrefetch() async {
    var token = await _storage.read("token");
    var response = await http.get(
      Uri.parse("$apiUrl/rider/"),
      headers: {"Authorization": "Bearer $token"},
    );
    var rider = RiderDataResponse.fromJson(jsonDecode(response.body)).rider;
    riderController.updateRider(
      rider,
    );
    setState(() {
      vehicle = rider.vehicle == null ? "scooty" : rider.vehicle!;
      drivinglicense = rider.drivinglicense == "" ? "" : rider.drivinglicense!;
    });
  }

  void handleSave() async {
    setState(() {
      loading = true;
    });
    final token = await _storage.read("token");
    try {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      var request = http.Request('PATCH', Uri.parse('$apiUrl/rider/update'));
      request.body =
          json.encode({"vehicle": vehicle, "drivinglicense": drivinglicense});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var profileData = RiderDataResponse.fromJson(jsonDecode(data));
        print(data);
        riderController.updateRider(profileData.rider);
      } else {
        Get.snackbar("Error", response.reasonPhrase!);
      }
      setState(() {
        loading = false;
      });
    } catch (e) {}
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
        title: const CustomAppBar(
          title: "Transport Type",
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 10,
          ),
          child: GetBuilder<RiderController>(
              init: RiderController(),
              builder: (ridercontroller) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          vehicle = "scooty";
                        });
                      },
                      child: Container(
                        height: 55,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: vehicle == "scooty"
                              ? Colors.transparent
                              : accentColor,
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            width: 2,
                            color: accentColor,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                "Scooty",
                                style: GoogleFonts.poppins(
                                  color: vehicle == "scooty"
                                      ? accentColor
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          vehicle = "bike";
                        });
                      },
                      child: Container(
                        height: 55,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: vehicle == "bike"
                              ? Colors.transparent
                              : accentColor,
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            width: 2,
                            color: accentColor,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                "Bike",
                                style: GoogleFonts.poppins(
                                  color: vehicle == "bike"
                                      ? accentColor
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      "Upload or Capture your both sides of Driving License. The photo must be clearly visible.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Text(
                          "Driving License: ",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: accentColor,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 25,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: getImage,
                              child: Text(
                                "Upload Driving License",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _launchURL(drivinglicense),
                              child: const Icon(
                                Icons.link,
                                color: Colors.blue,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    GestureDetector(
                      onTap: handleSave,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 50,
                        decoration: BoxDecoration(
                          color: accentColor,
                          border: Border.all(
                            width: 2,
                            color: accentColor,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 25,
                          ),
                          child: Center(
                            child: loading
                                ? const SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Text(
                                    "Save",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
