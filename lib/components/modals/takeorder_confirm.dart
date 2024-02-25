import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/screens/track_order.dart';
import 'package:instaport_rider/utils/toast_manager.dart';

class TakeOrderConfirm extends StatefulWidget {
  final String id;
  final Orders data;

  const TakeOrderConfirm({super.key, required this.id, required this.data});

  @override
  State<TakeOrderConfirm> createState() => _TakeOrderConfirmState();
}

class _TakeOrderConfirmState extends State<TakeOrderConfirm> {
  final _storage = GetStorage();
  RiderController riderController = Get.put(RiderController());

  void manageOrder() async {
    final token = await _storage.read("token");
    try {
      var response = await http.patch(
        Uri.parse("$apiUrl/rider/assign/${widget.id}"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        var data = RiderDataResponse.fromJson(jsonDecode(response.body));
        riderController.updateRider(data.rider);
        Get.back();
        Get.back();
        if (data.error) {
        } else {
          Get.to(
            () => TrackOrder(
              data: widget.data,
            ),
          );
        }
        ToastManager.showToast(data.message);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width - 50,
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 15.0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Confirm",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Are you sure you want to take order?",
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: manageOrder,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(width: 2, color: Colors.transparent),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      child: Center(
                        child: Text(
                          "Take order",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(width: 2, color: accentColor),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      child: Center(
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
