// ignore_for_file: deprecated_member_use, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/models/address_model.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/utils/timeformatter.dart';
import 'package:url_launcher/url_launcher.dart';

class AddressDetailsScreen extends StatefulWidget {
  final Address address;
  final String title;
  final int time;
  final int index;
  final bool scheduled;
  final List<OrderStatus> orderStatus;
  final Address? paymentAddress;
  final String type;

  const AddressDetailsScreen({
    super.key,
    required this.address,
    required this.title,
    required this.time,
    required this.orderStatus,
    required this.scheduled,
    required this.index,
    required this.type,
    this.paymentAddress,
  });

  @override
  State<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends State<AddressDetailsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchUrl(LatLng src, LatLng dest) async {
    final String url =
        "https://www.google.com/maps/dir/?api=1&origin=${src.latitude},${src.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=motorcycle&avoid=tolls&units=imperial&language=en&departure_time=now";
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  AppController appController = Get.put(AppController());
  final int minute = 60000;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.orderStatus.where(
              (element) {
                return element.message == widget.address.address;
              },
            ).isNotEmpty
                ? const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                  )
                : Text(
                    "${widget.index + 1}.",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(
              width: 4,
            ),
            Text(
              widget.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              width: 4,
            ),
            if (widget.type == "cod" && widget.paymentAddress != null &&
                widget.address.text == widget.paymentAddress!.text)
              Text(
                "(Payment Address)",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(
          height: 3,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Address: ",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.address.address,
              style: GoogleFonts.poppins(),
              softWrap: true,
            )
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Map: ",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => _launchUrl(
                LatLng(appController.currentposition.value.target.latitude,
                    appController.currentposition.value.target.longitude),
                LatLng(widget.address.latitude, widget.address.longitude),
              ),
              child: Text(
                widget.address.text,
                style: GoogleFonts.poppins(),
                softWrap: true,
              ),
            )
          ],
        ),
        if (widget.scheduled)
          const SizedBox(
            height: 5,
          ),
        if (widget.scheduled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "When to arrive at address: ",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                ),
                softWrap: true,
              ),
              Text(
                "${widget.address.date} - ${widget.address.time}",
                style: GoogleFonts.poppins(),
                softWrap: true,
              )
            ],
          ),
        if (!widget.scheduled)
          const SizedBox(
            height: 5,
          ),
        if (!widget.scheduled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Time: ",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                ),
                softWrap: true,
              ),
              Text(
                widget.title == "Pickup"
                    ? readTimestamp(widget.time + 45 * minute)
                    : readTimestamp(
                        widget.time + 60 * minute * widget.index + 45 * minute,
                      ),
                style: GoogleFonts.poppins(),
                softWrap: true,
              )
            ],
          ),
        const SizedBox(
          height: 5,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Phone Number: ",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
              softWrap: true,
            ),
            GestureDetector(
              onTap: () => _makePhoneCall(
                widget.address.phone_number,
              ),
              child: Text(
                widget.address.phone_number,
                style: GoogleFonts.poppins(),
                softWrap: true,
              ),
            )
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Instructions: ",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
              softWrap: true,
            ),
            Text(
              widget.address.instructions,
              style: GoogleFonts.poppins(),
              softWrap: true,
            )
          ],
        ),
      ],
    );
  }
}
