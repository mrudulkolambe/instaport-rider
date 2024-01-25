// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/components/label.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/models/rider_model.dart';

class ReferenceContacts extends StatefulWidget {
  const ReferenceContacts({super.key});

  @override
  State<ReferenceContacts> createState() => _ReferenceContactsState();
}

class _ReferenceContactsState extends State<ReferenceContacts> {
  final _storage = GetStorage();
  RiderController riderController = Get.put(RiderController());
  bool loading = false;
  int person = 0;
  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _relationcontroller = TextEditingController();
  final TextEditingController _phonenumbercontroller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void handleOpen(int index) {
    setState(() {
      person = index;
    });
    if (index == 0 && !riderController.rider.referenceContact1.isNull) {
      _namecontroller.text = riderController.rider.referenceContact1!.name;
      _relationcontroller.text =
          riderController.rider.referenceContact1!.relation;
      _phonenumbercontroller.text =
          riderController.rider.referenceContact1!.number;
    } else if (index == 1 && !riderController.rider.referenceContact2.isNull) {
      _namecontroller.text = riderController.rider.referenceContact2!.name;
      _relationcontroller.text =
          riderController.rider.referenceContact2!.relation;
      _phonenumbercontroller.text =
          riderController.rider.referenceContact2!.number;
    } else {
      _namecontroller.text = "";
      _relationcontroller.text = "";
      _phonenumbercontroller.text = "";
    }
    _openBottomSheet(context);
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
      if (person == 0) {
        request.body = json.encode({
          "reference_contact_1": {
            "name": _namecontroller.text,
            "relation": _relationcontroller.text,
            "phonenumber": _phonenumbercontroller.text,
          }
        });
      } else if (person == 1) {
        request.body = json.encode({
          "reference_contact_2": {
            "name": _namecontroller.text,
            "relation": _relationcontroller.text,
            "phonenumber": _phonenumbercontroller.text,
          }
        });
      }
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var profileData = RiderDataResponse.fromJson(jsonDecode(data));
        riderController.updateRider(profileData.rider);
        Navigator.of(context).pop();
      } else {
        Get.snackbar("Error", response.reasonPhrase!);
      }
      setState(() {
        loading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        loading = false;
      });
    }
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // const SizedBox(height: 20.0),
                  const Label(label: "Name of the reference person: "),
                  TextFormField(
                    controller: _namecontroller,
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Enter name of the reference person",
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
                        borderSide: const BorderSide(
                          width: 2,
                          color: Colors.black26,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          width: 2,
                          color: accentColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15.0),
                  const Label(label: "Relation with reference person: "),
                  TextFormField(
                    controller: _relationcontroller,
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Enter relation with reference person",
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
                        borderSide: const BorderSide(
                          width: 2,
                          color: Colors.black26,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          width: 2,
                          color: accentColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15.0),
                  const Label(label: "Reference person Mobile number: "),
                  TextFormField(
                    controller: _phonenumbercontroller,
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Enter relation with reference person",
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
                        borderSide: const BorderSide(
                          width: 2,
                          color: Colors.black26,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          width: 2,
                          color: accentColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15.0,
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
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.of(context).pop();
                  //   },
                  //   child: const Text('Close Bottom Sheet'),
                  // ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((value) {
      _namecontroller.text = "";
      _phonenumbercontroller.text = "";
      _relationcontroller.text = "";
    });
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
          title: "Reference Contacts",
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
                      "Someone who can attest to your dependability and dedication (such as a classmate, manager, or spouse/partner).",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      "Within the following 24 hours, we will get in touch with them and request recommendations.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      "The post for which you are applying won't be made public. If you'd like, you can reveal it on your own.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    GestureDetector(
                      onTap: () {
                        handleOpen(0);
                      },
                      child: Container(
                        height: 55,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
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
                                "Person 1",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
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
                        handleOpen(1);
                      },
                      child: Container(
                        height: 55,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
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
                                "Person 2",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
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
                          borderRadius: BorderRadius.circular(25),
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
