import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/utils/mask_fomatter.dart';
import 'package:instaport_rider/utils/toast_manager.dart';

class ProofOfAddress extends StatefulWidget {
  const ProofOfAddress({super.key});

  @override
  State<ProofOfAddress> createState() => _ProofOfAddressState();
}

class _ProofOfAddressState extends State<ProofOfAddress> {
  final _storage = GetStorage();
  final TextEditingController _addresscontroller = TextEditingController();
  final TextEditingController _aadharcontroller = TextEditingController();
  final TextEditingController _pancontroller = TextEditingController();
  RiderController riderController = Get.put(RiderController());
  bool loading = false;
  bool uploading = false;
  TextInputType keyboardType = TextInputType.text;

  void _updateKeyboardType() {
    setState(() {
      if (_pancontroller.text.length >= 5 && _pancontroller.text.length <= 9) {
        keyboardType = TextInputType.number;
      } else {
        keyboardType = TextInputType.text;
      }
    });
  }

  @override
  void dispose() {
    _pancontroller.removeListener(_updateKeyboardType);
    _pancontroller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pancontroller.addListener(_updateKeyboardType);
    if (riderController.rider.address == null) {
      _addresscontroller.text = "";
      _aadharcontroller.text = "";
      _pancontroller.text = "";
    } else {
      _addresscontroller.text = riderController.rider.address!;
      _aadharcontroller.text = riderController.rider.aadharcard!;
      _pancontroller.text = riderController.rider.pancard!;
    }
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
        "address": _addresscontroller.text,
        "aadhar_number": _aadharcontroller.text,
        "pan_number": _pancontroller.text,
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var profileData = RiderDataResponse.fromJson(jsonDecode(data));
        riderController.updateRider(profileData.rider);
        ToastManager.showToast(profileData.message);
      } else {
        ToastManager.showToast(response.reasonPhrase!);
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
        toolbarHeight: 60,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const CustomAppBar(
          title: "Proof Of Address",
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
                    Text(
                      "Upload or Capture all your above mentioned ID's. Upload both sides. The photo must be clearly visible.",
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
                          "Address: ",
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
                      keyboardType: TextInputType.streetAddress,
                      controller: _addresscontroller,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your address",
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black38,
                        ),
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
                          "Aadhar Card: ",
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
                      inputFormatters: [aadharcardMask],
                      keyboardType: TextInputType.number,
                      controller: _aadharcontroller,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your aadhar card number",
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black38,
                        ),
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
                          "PAN Card: ",
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
                      inputFormatters: [pancardMask],
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: keyboardType,
                      controller: _pancontroller,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your pancard number",
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black38,
                        ),
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
                  ],
                );
              }),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
