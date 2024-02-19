import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/label.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/screens/login.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/services/tracking_service.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  bool loading = false;
  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _phonecontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();
  final RiderController riderController = Get.put(RiderController());
  final TrackingService trackingService = Get.find<TrackingService>();

  void writeData(String token) async {
    try {
      final riderData = await http.get(Uri.parse('$apiUrl/rider/'),
          headers: {'Authorization': 'Bearer $token'});
      final userData = RiderDataResponse.fromJson(jsonDecode(riderData.body));
      riderController.updateRider(userData.rider);
      DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref("/rider/${userData.rider.id}");
      // trackingService.setUser(userData.rider.id);
      databaseReference.set({
        'timestamp': DateTime.now().toString(),
        'id': userData.rider.id,
        'latitude': 0.0,
        'longitude': 0.0,
      }).then((_) {
        Get.snackbar("Success", "You can proceed with your login!");
        Get.to(() => SplashScreen());
      }).catchError((error) {
        print('Error saving entry to the database: $error');
      });
    } catch (error) {
      print('Error creating entry: $error');
      // Handle errors or provide user feedback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 35.0,
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Text(
                      "Sign Up",
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 32),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Column(
                  children: [
                    Column(
                      children: [
                        const Label(label: "Full Name: "),
                        TextFormField(
                          controller: _namecontroller,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: "Enter your full name",
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.black38),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black26),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black26),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: accentColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 15),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Label(label: "Phone Number: "),
                        TextFormField(
                          controller: _phonecontroller,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: "Enter your phone number",
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.black38),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black26),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black26),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: accentColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 15),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Label(label: "Password: "),
                        TextFormField(
                          controller: _passwordcontroller,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: "Enter your Password",
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.black38),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black26),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black26),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: accentColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: GestureDetector(
                              onTap: () async {
                                setState(() {
                                  loading = true;
                                });
                                const String url = '$apiUrl/rider/signup';
                                try {
                                  final response = await http.post(
                                    Uri.parse(url),
                                    headers: {
                                      'Content-Type': 'application/json'
                                    },
                                    body: jsonEncode({
                                      'fullname': _namecontroller.text,
                                      'mobileno': _phonecontroller.text,
                                      'password': _passwordcontroller.text,
                                    }),
                                  );
                                  print(response.body);
                                  final data = SignInResponse.fromJson(
                                    json.decode(response.body),
                                  );
                                  print(data.error);
                                  GetSnackBar(
                                    title: "Message",
                                    message: data.message,
                                  );
                                  if (data.error) {
                                    setState(() {
                                      loading = false;
                                    });
                                  } else {
                                    writeData(data.token);
                                    setState(() {
                                      loading = false;
                                    });
                                  }
                                  // ignore: empty_catches
                                } catch (error) {
                                  setState(() {
                                    loading = false;
                                  });
                                }
                              },
                              child: Container(
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: accentColor,
                                ),
                                child: Center(
                                  child: loading
                                      ? const SpinKitThreeBounce(
                                          color: Colors.white,
                                          size: 15,
                                        )
                                      : Text(
                                          "Sign Up",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            )),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Get.to(() => const Login()),
                              child: Text(
                                "Login",
                                style: GoogleFonts.poppins(
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
