import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/label.dart';
import 'package:instaport_rider/constants/colors.dart';

class DisplayInput extends StatelessWidget {
  final String label;
  final String value;

  const DisplayInput({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Label(label: "$label: "),
        TextFormField(
          initialValue: value,
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
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
      ],
    );
  }
}
