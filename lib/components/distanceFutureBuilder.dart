import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/services/location_service.dart';

class DistanceFutureBuilder extends StatefulWidget {
  final LatLng src;
  final LatLng dest;

  const DistanceFutureBuilder(
      {super.key, required this.src, required this.dest});

  @override
  State<DistanceFutureBuilder> createState() => _DistanceFutureBuilderState();
}

class _DistanceFutureBuilderState extends State<DistanceFutureBuilder> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: LocationService().fetchDistance(
        widget.src,
        widget.dest,
      ),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            "Loading...",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          );
        } else {
          if (snapshot.hasError) {
            // Handle error
            return Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            );
          } else {
            return Text(
              '${(snapshot.data! / 1000).toPrecision(2)}km away',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            );
          }
        }
      },
    );
  }
}
