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

class BankDetails extends StatefulWidget {
  const BankDetails({super.key});

  @override
  State<BankDetails> createState() => _BankDetailsState();
}

class _BankDetailsState extends State<BankDetails> {
  final _storage = GetStorage();
  final TextEditingController _accHolderName = TextEditingController();
  final TextEditingController _accountNumber = TextEditingController();
  final TextEditingController _ifscode = TextEditingController();
  RiderController riderController = Get.put(RiderController());
  bool loading = false;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
      _accHolderName.text = riderController.rider.accname != null ? riderController.rider.accname! : "";
      _accountNumber.text = riderController.rider.accno != null ? riderController.rider.accno! : "";
      _ifscode.text = riderController.rider.ifsc != null ? riderController.rider.ifsc! : "";
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
        "acc_holder": _accHolderName.text,
        "acc_no": _accountNumber.text,
        "acc_ifsc": _ifscode.text,
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var profileData = RiderDataResponse.fromJson(jsonDecode(data));
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
          title: "Bank Details",
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
                      children: [
                        Text(
                          "Name of Account Holder: ",
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
                      controller: _accHolderName,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your account holder name",
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
                          "Account Number: ",
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
                      keyboardType: TextInputType.number,
                      controller: _accountNumber,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your account number",
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
                          "IFSC Code: ",
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
                      controller: _ifscode,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your bank IFSC code",
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
