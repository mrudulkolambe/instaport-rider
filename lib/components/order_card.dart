import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaport_rider/components/distanceFutureBuilder.dart';
import 'package:instaport_rider/components/modals/takeorder_confirm.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/models/address_model.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/screens/track_order.dart';
import 'package:instaport_rider/services/location_service.dart';
import 'package:instaport_rider/utils/obsecure_text.dart';
import 'package:instaport_rider/utils/timeformatter.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderCard extends StatefulWidget {
  final Orders data;
  final bool modal;
  final bool isSelected;
  final Function(bool)? onSelectionChanged;

  const OrderCard({
    super.key,
    required this.data,
    required this.modal,
    required this.isSelected,
    this.onSelectionChanged,
  });

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
      data: widget.data,
    ));
  }

  Future<void> _launchUrlMap(
      LatLng src, LatLng dest, List<Address> droplocations) async {
  String endpoint = "";
    if (droplocations.isEmpty) {
      endpoint =
          "https://www.google.com/maps/dir/?api=1&origin=${src.latitude},${src.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=motorcycle&avoid=tolls&units=imperial&language=en&departure_time=now";
    } else {
      final List<LatLng> dropArr = [];
      dropArr.add(dest);
      if(droplocations.length > 1){
        for (var i = 0; i < droplocations.length - 2; i++) {
          dropArr.add(LatLng(droplocations[i].latitude, droplocations[i].longitude)); 
        }
      }
      final String waypointsString = dropArr
          .map((address) => '${address.latitude},${address.longitude}')
          .join('|');
      endpoint =
          "https://www.google.com/maps/dir/?api=1&origin=${src.latitude},${src.longitude}&destination=${droplocations.last.latitude},${droplocations.last.longitude}&travelmode=driving&avoid=tolls&units=imperial&language=en&departure_time=now&waypoints=$waypointsString";
    }

    if (!await launchUrl(
      Uri.parse(endpoint),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $endpoint');
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

  List<Widget> buildListWidget() {
    return widget.data.droplocations.asMap().entries.map((e) {
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
                      e.value.latitude,
                      e.value.longitude,
                    ),
                    LatLng(
                      e.value.latitude,
                      e.value.longitude,
                    ),
                  ),
                  child: Text(
                    obscureString(e.value.text),
                    softWrap: true,
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
                "${widget.data.distances[e.key + 1].toString()}km away",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      );
    }).toList();
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
                        "Rs. ${(widget.data.amount * (100 - widget.data.commission) / 100).toPrecision(2)}",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                          focusColor: accentColor,
                          hoverColor: accentColor,
                          style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => accentColor)),
                          onPressed: () {
                            _launchUrlMap(
                              LatLng(
                                widget.data.pickup.latitude,
                                widget.data.pickup.longitude,
                              ),
                              LatLng(
                                widget.data.drop.latitude,
                                widget.data.drop.longitude,
                              ),
                              widget.data.droplocations,
                            );
                          },
                          icon: Icon(
                            Icons.directions,
                            color: Colors.black,
                          ))
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.data.droplocations.length + 2} Addresses (${widget.data.payment_method == "cod" ? "COD" : "Online"})",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.data.delivery_type == "scheduled")
                        const Icon(
                          Icons.timer,
                          color: accentColor,
                          size: 18,
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
                                            .target.longitude,
                                      ),
                                      LatLng(
                                        widget.data.pickup.latitude,
                                        widget.data.pickup.longitude,
                                      ),
                                    ),
                                    child: Text(
                                      obscureString(widget.data.pickup.text),
                                      softWrap: true,
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
                                widget.data.status == "delivered"
                                    ? Text(
                                        "0.0km away",
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : GetBuilder<AppController>(
                                        init: AppController(),
                                        builder: (controller) {
                                          return DistanceFutureBuilder(
                                            src: LatLng(
                                              controller.currentposition.value
                                                  .target.latitude,
                                              controller.currentposition.value
                                                  .target.longitude,
                                            ),
                                            dest: LatLng(
                                              widget.data.pickup.latitude,
                                              widget.data.pickup.longitude,
                                            ),
                                          );
                                        }),
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
                                LatLng(
                                  widget.data.pickup.latitude,
                                  widget.data.pickup.longitude,
                                ),
                                LatLng(
                                  widget.data.drop.latitude,
                                  widget.data.drop.longitude,
                                ),
                              ),
                              child: Text(
                                obscureString(widget.data.drop.text),
                                softWrap: true,
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
                            "${widget.data.distances[0].toString()}km away",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ...buildListWidget(),
                      const Divider(),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Text(
                            "Order ID: ",
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
                              "#${widget.data.id.substring(20)}",
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
                        height: 3,
                      ),
                      Row(
                        children: [
                          Text(
                            "Vehicle: ",
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
                              widget.data.vehicle,
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
                            "Pickup: ",
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
                              "${readTimestampAsTime(widget.data.time_stamp)} - ${readTimestampAsTime(widget.data.time_stamp + 45 * 60000)}",
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
                                Get.to(() => TrackOrder(data: widget.data));
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
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
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
      distance = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 10,
        ),
        GestureDetector(
          onTap: () {
            if (widget.data.status == "new") {
              _openBottomSheet(context);
            } else {
              Get.to(() => TrackOrder(data: widget.data));
            }
          },
          // onLongPress: () {
          //   widget.onSelectionChanged(!widget.isSelected);
          //   print(!widget.isSelected);
          // },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: accentColor,
                width: 1,
              ),
              // color: widget.isSelected ? Colors.blue[50] : Colors.white,
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
                  // Checkbox(
                  //   value: widget.isSelected,
                  //   onChanged: (value) {
                  //     // Call the onSelectionChanged callback when the checkbox changes
                  //     widget.onSelectionChanged(value ?? false);
                  //   },
                  // ),
        
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rs. ${(widget.data.amount * (100 - widget.data.commission) / 100).toPrecision(2)}",
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.data.droplocations.length + 2} Addresses (${widget.data.payment_method == "cod" ? "COD" : "Online"})",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.data.delivery_type == "scheduled")
                        const Icon(
                          Icons.timer,
                          color: accentColor,
                          size: 18,
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
                              widget.data.status == "new"
                                  ? obscureString(widget.data.pickup.text)
                                  : widget.data.pickup.text,
                              softWrap: true,
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
                          widget.data.status == "delivered"
                              ? Text(
                                  "0.0km away",
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : GetBuilder<AppController>(
                                  init: AppController(),
                                  builder: (controller) {
                                    return DistanceFutureBuilder(
                                      src: LatLng(
                                        controller
                                            .currentposition.value.target.latitude,
                                        controller
                                            .currentposition.value.target.longitude,
                                      ),
                                      dest: LatLng(
                                        widget.data.pickup.latitude,
                                        widget.data.pickup.longitude,
                                      ),
                                    );
                                  }),
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
                              widget.data.status == "new"
                                  ? obscureString(widget.data.drop.text)
                                  : widget.data.drop.text,
                              softWrap: true,
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
                            "${widget.data.distances[0].toString()}km away",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      if (widget.data.droplocations.length > 1)
                        Column(
                          children: [
                            const SizedBox(
                              height: 2,
                            ),
                            Row(
                              children: [
                                RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    "...",
                                    style: GoogleFonts.poppins(
                                        fontSize: 30, letterSpacing: 2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                          ],
                        ),
                      if (widget.data.droplocations.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
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
                                    widget.data.status == "new"
                                        ? obscureString(
                                            widget.data.droplocations.last.text)
                                        : widget.data.droplocations.last.text,
                                    softWrap: true,
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
                                  "${widget.data.distances[widget.data.distances.length - 1].toString()}km away",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
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
                        height: 3,
                      ),
                      Row(
                        children: [
                          Text(
                            "Vehicle: ",
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
                              widget.data.vehicle,
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
                            "Pickup: ",
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
                              "${readTimestampAsTime(widget.data.time_stamp)} - ${readTimestampAsTime(widget.data.time_stamp + 45 * 60000)}",
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
