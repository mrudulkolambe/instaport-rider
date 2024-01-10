import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/order_card.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:http/http.dart' as http;

class TakeOrderDialog extends StatefulWidget {
  final Orders data;

  const TakeOrderDialog({super.key, required this.data});

  @override
  State<TakeOrderDialog> createState() => _TakeOrderDialogState();
}

final _storage = GetStorage();

class _TakeOrderDialogState extends State<TakeOrderDialog> {
  void manageOrder() async {
    final token = await _storage.read("token");
    try {
      var response = await http.patch(
          Uri.parse("$apiUrl/rider/assign/${widget.data.id}"),
          headers: {"Authorization": "Bearer $token"});
    } catch (e) {}
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
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OrderCard(data: widget.data, modal: false),
            const SizedBox(
              height: 10,
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
