import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/models/address_model.dart';

class AddressDetails extends StatelessWidget {
  final Address address;
  final String title;
  final bool scheduled;

  const AddressDetails({
    super.key,
    required this.address,
    required this.title,
    required this.scheduled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
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
              address.address,
              style: GoogleFonts.poppins(),
              softWrap: true,
            )
          ],
        ),
        if (scheduled)
          const SizedBox(
            height: 5,
          ),
        if (scheduled)
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
                "${address.date} - ${address.time}",
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
            Text(
              address.phone_number,
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
              "Instructions: ",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
              softWrap: true,
            ),
            Text(
              address.instructions,
              style: GoogleFonts.poppins(),
              softWrap: true,
            )
          ],
        ),
      ],
    );
  }
}
