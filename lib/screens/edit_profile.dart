import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/cloudinary_upload.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/models/upload.dart';
import 'package:instaport_rider/utils/image_modifier.dart';
import 'package:instaport_rider/utils/mask_fomatter.dart';
import 'package:instaport_rider/utils/toast_manager.dart';
import 'package:instaport_rider/utils/validator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  RiderController riderController = Get.put(RiderController());
  final _storage = GetStorage();
  final TextEditingController _fullnamecontroller = TextEditingController();
  final TextEditingController _phonecontroller = TextEditingController();
  final TextEditingController _agecontroller = TextEditingController();
  bool loading = false;
  bool uploading = false;
  String image = "";

  @override
  void initState() {
    super.initState();
    handlePrefetch();
  }

  Future<bool> requestCameraPermission() async {
    setState(() {
      uploading = true;
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

  Future<SingleUploadResponse?> uploadSingleFile(File file, String path) async {
    var request = http.MultipartRequest('POST', Uri.parse("$apiUrl/upload"));
    request.fields.addAll({'path': path});
    request.files.add(await http.MultipartFile.fromPath('files', file.path));
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      final result = await response.stream.bytesToString();
      final data = SingleUploadResponse.fromJson(jsonDecode(result));
      setState(() {
        image = data.media.url;
      });
      handleSave();
      return data;
    } else {
      return null;
    }
  }

  Future<void> getImage() async {
    bool permissionGranted = await requestCameraPermission();
    if (permissionGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        File pickedImageFile = File(image.path);
        int sizeInBytes = await pickedImageFile.length();
        double sizeInMB = sizeInBytes / (1024 * 1024);
        if (sizeInMB <= 10.0) {
          uploadSingleFile(pickedImageFile, "rider/profile/");
        } else {
          ToastManager.showToast("Size should be less than 10MB");
          setState(() {
            uploading = false;
          });
        }
      } else {
        setState(() {
          uploading = false;
        });
      }
    } else {
      setState(() {
        uploading = false;
      });
      openAppSettings();
      ToastManager.showToast('Permission to access gallery denied');
    }
    return;
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
      request.body = json.encode({
        "fullname": _fullnamecontroller.text,
        "age": _agecontroller.text,
        "mobileno": _phonecontroller.text,
        "image": {
          "url": image,
          "status": riderController.rider.image!.status,
          "type": "image"
        }
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

        print(response.statusCode);
      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        print(data);
        var profileData = RiderDataResponse.fromJson(jsonDecode(data));
        riderController.updateRider(profileData.rider);
        ToastManager.showToast(profileData.message);
      } else {
        ToastManager.showToast(response.reasonPhrase!);
      }
      setState(() {
        uploading = false;
        loading = false;
      });
    } catch (e) {}
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
    _fullnamecontroller.text = rider.fullname;
    _phonecontroller.text = rider.mobileno;
    _agecontroller.text = rider.age;
    setState(() {
      image = rider.image!.url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const CustomAppBar(
          title: "Edit Profile",
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: getImage,
                              child: image != ""
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        image,
                                      ),
                                      radius: 70,
                                    )
                                  : Container(
                                      height: 140,
                                      width: 140,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 4,
                                          color: accentColor,
                                        ),
                                        borderRadius: BorderRadius.circular(70),
                                      ),
                                    ),
                            ),
                            if (uploading)
                              Container(
                                height: 140,
                                width: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(70),
                                ),
                                child: const CircularProgressIndicator(
                                  strokeCap: StrokeCap.butt,
                                  color: accentColor,
                                ),
                              )
                          ],
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Text(
                          "Fullname: ",
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
                    TextFormField(
                      keyboardType: TextInputType.name,
                      controller: _fullnamecontroller,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            width: 2,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(width: 2, color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(width: 2, color: accentColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Text(
                          "Phone number: ",
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
                    TextFormField(
                      keyboardType: TextInputType.phone,
                      validator: (value) => validatePhoneNumber(value!),
                      inputFormatters: [phoneNumberMask],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _phonecontroller,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your phone number",
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            width: 2,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(width: 2, color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(width: 2, color: accentColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Text(
                          "Age: ",
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
                    TextFormField(
                      inputFormatters: [ageMask],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.number,
                      controller: _agecontroller,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your age",
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.black38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            width: 2,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(width: 2, color: Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(width: 2, color: accentColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
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
                    const SizedBox(
                      height: 15,
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
