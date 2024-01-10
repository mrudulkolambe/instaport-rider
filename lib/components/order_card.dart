import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaport_rider/components/modals/takeorder_confirm.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/screens/track_order.dart';
import 'package:instaport_rider/services/location_service.dart';
import 'package:instaport_rider/utils/timeformatter.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderCard extends StatefulWidget {
  final Orders data;
  final bool modal;
  const OrderCard({super.key, required this.data, required this.modal});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  AppController appController = Get.put(AppController());
  double distance = 0.0;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _handleDistance();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void confirmTakeOrder() {
    Get.dialog(TakeOrderConfirm(
      id: widget.data.id,
    ));
  }

  Future<void> _launchUrl(LatLng src, LatLng dest) async {
    final String url =
        "https://www.google.com/maps/dir/?api=1&origin=${src.latitude},${src.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=driving&avoid=tolls&units=imperial&language=en&departure_time=now";
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      enableDrag: true,
      isDismissible: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rs. ${(widget.data.amount * 0.8).toPrecision(0)}",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "#${widget.data.id.substring(20)}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Text(
                        "2 Addresses (${widget.data.payment_method == "cod" ? "Pending" : "Paid"})",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GetBuilder<AppController>(
                      init: AppController(),
                      builder: (appcontroler) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  weight: 1.2,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _launchUrl(
                                        LatLng(
                                            appcontroler.currentposition.value
                                                .target.latitude,
                                            appcontroler.currentposition.value
                                                .target.longitude),
                                        LatLng(widget.data.pickup.latitude,
                                            widget.data.pickup.longitude)),
                                    child: Text(
                                      widget.data.pickup.text,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 22,
                                ),
                                Text(
                                  "${(widget.data.distance / 1000).toPrecision(2)}km away",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      }),
                  const SizedBox(
                    height: 10,
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            weight: 1.2,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _launchUrl(
                                  LatLng(widget.data.pickup.latitude,
                                      widget.data.pickup.longitude),
                                  LatLng(widget.data.drop.latitude,
                                      widget.data.drop.longitude)),
                              child: Text(
                                widget.data.drop.text,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 22,
                          ),
                          Text(
                            "${(distance / 1000).toPrecision(2)}km away",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Divider(),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Text(
                            "Commodity: ",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          Expanded(
                            child: Text(
                              "${widget.data.package} (${widget.data.parcel_weight})",
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Row(
                        children: [
                          Text(
                            "Time: ",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          Expanded(
                            child: Text(
                              readTimestamp(widget.data.time_stamp),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              if (widget.data.status == "new") {
                                confirmTakeOrder();
                              } else {
                                Get.to(TrackOrder(data: widget.data));
                              }
                            },
                            child: Container(
                              width:
                                  MediaQuery.of(context).size.width * 0.48 - 25,
                              height: 50,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 2,
                                  color: accentColor,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  widget.data.status == "new"
                                      ? "Take Order"
                                      : "View",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width:
                                MediaQuery.of(context).size.width * 0.48 - 25,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 2,
                                color: accentColor,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Close",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((value) {
      print('Bottom sheet closed');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMounted = true;
  }

  void _handleDistance() async {
    // if (!_isMounted) return;
    var data = await LocationService().fetchDistance(
      LatLng(widget.data.drop.latitude, widget.data.drop.longitude),
      LatLng(widget.data.pickup.latitude, widget.data.pickup.longitude),
    );

    if (!_isMounted) return;
    setState(() {
      distance = data.rows[0].elements[0].distance!.value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _openBottomSheet(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: accentColor,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4F000000),
              blurRadius: 18,
              offset: Offset(2, 4),
              spreadRadius: -15,
            )
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rs. ${(widget.data.amount * 0.8).toPrecision(0)}",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "#${widget.data.id.substring(20)}",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Text(
                    "2 Addresses (${widget.data.payment_method == "cod" ? "Pending" : "Paid"})",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        weight: 1.2,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          widget.data.pickup.text,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 22,
                      ),
                      Text(
                        "${(widget.data.distance / 1000).toPrecision(2)}km away",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, weight: 1.2),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          widget.data.drop.text,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 22,
                      ),
                      Text(
                        "${(distance / 1000).toPrecision(2)}km away",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Text(
                        "Commodity: ",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Expanded(
                        child: Text(
                          "${widget.data.package} (${widget.data.parcel_weight})",
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Row(
                    children: [
                      Text(
                        "Time: ",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Expanded(
                        child: Text(
                          readTimestamp(widget.data.time_stamp),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
