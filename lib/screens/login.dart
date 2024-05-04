import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/label.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/firebase_messaging/firebase_messaging.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/screens/create_account.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/screens/forget_password.dart';
import 'package:instaport_rider/screens/home.dart';
import 'package:instaport_rider/screens/inreview.dart';
import 'package:instaport_rider/services/tracking_service.dart';
import 'package:instaport_rider/utils/mask_fomatter.dart';
import 'package:instaport_rider/utils/toast_manager.dart';
import 'package:instaport_rider/utils/validator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _storage = GetStorage();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool loading = false;
  bool show = false;
  final RiderController riderController = Get.put(RiderController());
  final TrackingService trackingService = Get.find<TrackingService>();
  late FToast ftoast;

  @override
  void initState() {
    ftoast = FToast();
    ftoast.init(context);
    super.initState();
  }

  void writeData(String token) async {
    try {
      final riderData = await http.get(Uri.parse('$apiUrl/rider/'),
          headers: {'Authorization': 'Bearer $token'});
      final userData = RiderDataResponse.fromJson(jsonDecode(riderData.body));
      riderController.updateRider(userData.rider);
      trackingService.setUser(userData.rider.id);
      Get.to(() => const SplashScreen());
    } catch (error) {
      print('Error creating entry: $error');
      // Handle errors or provide user feedback
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Text(
                      "Sign In",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 32,
                      ),
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
                        const Label(label: "Phone Number: "),
                        TextFormField(
                          inputFormatters: [phoneNumberMask],
                          validator: (value) => validatePhoneNumber(value!),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.phone,
                          controller: _phoneController,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: '+91 00000 00000',
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
                                  width: 2, color: Colors.black26),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  width: 2, color: accentColor),
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
                        const Label(label: "Password: "),
                        TextFormField(
                          controller: _passwordController,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight:
                                show ? FontWeight.normal : FontWeight.w900,
                          ),
                          obscureText: !show,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                !show ? Icons.visibility : Icons.visibility_off,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  show = !show;
                                });
                              },
                            ),
                            hintText: "Enter your Password",
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
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () => Get.to(() => const ForgetPassword()),
                              child: Text(
                                "Forget Password?",
                                style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: GestureDetector(
                              onTap: loading
                                  ? null
                                  : () async {
                                      setState(() {
                                        loading = true;
                                      });
                                      String? fcmtoken =
                                          await FirebaseMessagingAPI()
                                              .initNotifications();
                                      const String url = '$apiUrl/rider/signin';
                                      try {
                                        final response = await http.post(
                                          Uri.parse(url),
                                          headers: {
                                            'Content-Type': 'application/json'
                                          },
                                          body: jsonEncode({
                                            'mobileno': _phoneController.text,
                                            'password':
                                                _passwordController.text,
                                            'fcmtoken': fcmtoken ?? ""
                                          }),
                                        );
                                        final data = SignInResponse.fromJson(
                                          json.decode(response.body),
                                        );
                                        ToastManager.showToast(data.message);
                                        if (data.error) {
                                        } else {
                                          _storage.write("token", data.token!);
                                          writeData(data.token!);
                                        }
                                        // ignore: empty_catches
                                      } catch (error) {
                                        ToastManager.showToast(
                                            error.toString());
                                      }
                                      setState(() {
                                        loading = false;
                                      });
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
                                          "Sign In",
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600),
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
                              "Don't have an account? ",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Get.to(() => const CreateAccount()),
                              child: Text(
                                "Sign Up",
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
