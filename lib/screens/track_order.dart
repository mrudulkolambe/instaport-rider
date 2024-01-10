// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/components/display_input.dart';
import 'package:instaport_rider/components/label.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrder extends StatefulWidget {
  final Orders data;

  const TrackOrder({super.key, required this.data});

  @override
  State<TrackOrder> createState() => _TrackOrderState();
}

class _TrackOrderState extends State<TrackOrder> with TickerProviderStateMixin {
  Set<Marker> _markers = {};
  Set<Polyline> _polylineSet = {};
  bool loading = false;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  late GoogleMapController newgooglemapcontroller;
  List<LatLng> pLineCoordinatedList = [];
  final Key _mapKey = UniqueKey();
  AppController appController = Get.put(AppController());
  late StreamSubscription<Position> positionStream;
  int modalState = 0;
  late TabController _tabController;
  int _expandedIndex = -1; // Track the index of the currently expanded tile

  void _handleExpansion(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = -1; // Collapse the currently expanded tile
      } else {
        _expandedIndex = index; // Expand the selected tile
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMap();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    // positionStream.cancel();
  }

  void _initializeMap() async {
    newgooglemapcontroller = await _mapControllerCompleter.future;
    markersAndPolylines(widget.data);
  }

  void markersAndPolylines(Orders order) async {
    Set<Marker> funcmarkers = {};
    Set<Polyline> funcpolyline = {};
    Marker pickupmarker = Marker(
      markerId: MarkerId(order.pickup.text),
      position: LatLng(
        order.pickup.latitude,
        order.pickup.longitude,
      ),
    );

    Marker dropmarker = Marker(
      markerId: MarkerId(order.drop.text),
      position: LatLng(
        order.drop.latitude,
        order.drop.longitude,
      ),
    );

    // newgooglemapcontroller.animateCamera(
    //   CameraUpdate.newCameraPosition(
    //     CameraPosition(
    //       target: LatLng(
    //         order.pickup.latitude,
    //         order.pickup.longitude,
    //       ),
    //       zoom: 14.14,
    //     ),
    //   ),
    // );
    final directionData = await LocationService().fetchDirections(
      order.pickup.latitude,
      order.pickup.longitude,
      order.drop.latitude,
      order.drop.longitude,
    );
    PolylinePoints pPoints = PolylinePoints();

    List<PointLatLng> decodePolylinePointsResult =
        pPoints.decodePolyline(directionData.e_points!);
    pLineCoordinatedList.clear();

    if (decodePolylinePointsResult.isNotEmpty) {
      for (var pointLatLng in decodePolylinePointsResult) {
        pLineCoordinatedList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    Polyline polyline = Polyline(
      polylineId: const PolylineId("main"),
      color: Colors.black,
      jointType: JointType.round,
      endCap: Cap.roundCap,
      geodesic: true,
      width: 5,
      points: pLineCoordinatedList,
    );
    _polylineSet.clear();
    funcmarkers.add(pickupmarker);
    funcmarkers.add(dropmarker);
    funcpolyline.add(polyline);

    setState(() {
      // _mapKey = UniqueKey();
      _markers = funcmarkers;
      _polylineSet = funcpolyline;
    });
    repositionGoogleMaps(LatLng(order.pickup.latitude, order.pickup.longitude),
        LatLng(order.drop.latitude, order.drop.longitude));
  }

  void _getCurrentLocation() {}

  void repositionGoogleMaps(LatLng src, LatLng dest) {
    LatLngBounds boundsLatLng;
    if (src.latitude > dest.latitude && src.longitude > dest.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          dest.latitude,
          dest.longitude,
        ),
        northeast: LatLng(
          src.latitude,
          src.longitude,
        ),
      );
    } else if (src.longitude > dest.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          src.latitude,
          dest.longitude,
        ),
        northeast: LatLng(
          dest.latitude,
          src.longitude,
        ),
      );
    } else if (src.latitude > dest.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          dest.latitude,
          src.longitude,
        ),
        northeast: LatLng(
          src.latitude,
          dest.longitude,
        ),
      );
    } else {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          src.latitude,
          src.longitude,
        ),
        northeast: LatLng(
          dest.latitude,
          dest.longitude,
        ),
      );
    }
    newgooglemapcontroller
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    print(url);
    if (await canLaunchUrl(Uri.parse(url))) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      useSafeArea: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: [
                      Text(
                        "Order #${widget.data.id.substring(18)}",
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 2.5,
                    enableFeedback: false,
                    labelStyle:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    labelColor: Colors.black,
                    indicatorColor: accentColor,
                    unselectedLabelColor: Colors.black26,
                    tabs: [
                      Tab(text: 'Details'), // Tab 1: Details
                      Tab(text: 'Breakdown'), // Tab 2: Breakdown
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8 - 30,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Rs. ${(widget.data.amount).toPrecision(2).toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Weight: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    widget.data.parcel_weight,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Parcel: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    widget.data.package,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Customer Name: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  Text(
                                    widget.data.customer.fullname,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Customer No.: ",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  GestureDetector(
                                    onTap: () => _makePhoneCall(
                                      widget.data.customer.mobileno,
                                    ),
                                    child: Text(
                                      widget.data.customer.mobileno,
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Card(
                                  borderOnForeground: true,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      4.0,
                                    ), // Optional: Adjust the border radius as needed
                                    side: BorderSide
                                        .none, // This removes the border
                                  ),
                                  child: ExpansionTile(
                                    onExpansionChanged: (bool expanded) {
                                      _handleExpansion(expanded ? 0 : -1);
                                    },
                                    backgroundColor:
                                        Colors.black.withOpacity(0.01),
                                    collapsedBackgroundColor:
                                        Colors.black.withOpacity(0.01),
                                    trailing: const Icon(Icons.expand_more),
                                    title: Text(
                                      "Pickup Point",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(widget.data.pickup.address),
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        width: double.infinity,
                                        child: Column(
                                          children: [
                                            DisplayInput(
                                              label: "Pickup Point",
                                              value: widget.data.pickup.address,
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            DisplayInput(
                                              label: "Phone No",
                                              value: widget
                                                  .data.pickup.phone_number,
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            DisplayInput(
                                              label: "Instructions",
                                              value: widget
                                                  .data.pickup.instructions,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )),
                              const SizedBox(
                                height: 10,
                              ),
                              Card(
                                borderOnForeground: true,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    4.0,
                                  ), // Optional: Adjust the border radius as needed
                                  side: BorderSide
                                      .none, // This removes the border
                                ),
                                child: ExpansionTile(
                                  onExpansionChanged: (bool expanded) {
                                    _handleExpansion(expanded ? 1 : -1);
                                  },
                                  backgroundColor:
                                      Colors.black.withOpacity(0.01),
                                  collapsedBackgroundColor:
                                      Colors.black.withOpacity(0.01),
                                  trailing: const Icon(Icons.expand_more),
                                  title: Text(
                                    "Drop Point",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(widget.data.drop.address),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      width: double.infinity,
                                      child: Column(
                                        children: [
                                          DisplayInput(
                                            label: "Drop Point",
                                            value: widget.data.drop.address,
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          DisplayInput(
                                            label: "Phone No",
                                            value:
                                                widget.data.drop.phone_number,
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          DisplayInput(
                                            label: "Instructions",
                                            value:
                                                widget.data.drop.instructions,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        Center(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Instaport Commission",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "- ₹${(widget.data.amount * 0.2).toPrecision(1).toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 7,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Rider Charge",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "+ ₹${(widget.data.amount * 0.8).toPrecision(1).toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 7,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Parcel Charge",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "₹${(widget.data.amount).toPrecision(1).toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((value) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: CustomAppBar(
          title: "Track #${widget.data.id.substring(18)}",
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Stack(children: [
              SizedBox(
                height: MediaQuery.of(context).size.height - 70 - 100,
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: [
                    GoogleMap(
                      key: _mapKey,
                      polylines: _polylineSet,
                      markers: {
                        Marker(
                          markerId: MarkerId(widget.data.pickup.text),
                          position: LatLng(
                            widget.data.pickup.latitude,
                            widget.data.pickup.longitude,
                          ),
                        ),
                        Marker(
                          markerId: MarkerId(widget.data.drop.text),
                          position: LatLng(
                            widget.data.drop.latitude,
                            widget.data.drop.longitude,
                          ),
                        ),
                      },
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          widget.data.pickup.latitude,
                          widget.data.pickup.longitude,
                        ),
                        zoom: 12.14,
                      ),
                      zoomControlsEnabled: false,
                      onMapCreated: (GoogleMapController controller) {
                        if (!_mapControllerCompleter.isCompleted) {
                          _mapControllerCompleter.complete(controller);
                        }
                        newgooglemapcontroller = controller;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: IconButton(
                                color: Colors.white,
                                onPressed: () {
                                  repositionGoogleMaps(
                                      LatLng(widget.data.pickup.latitude,
                                          widget.data.pickup.longitude),
                                      LatLng(widget.data.drop.latitude,
                                          widget.data.drop.longitude));
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateColor.resolveWith(
                                    (states) => accentColor,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.location_on_rounded,
                                  size: 22,
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 70 - 95,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _openBottomSheet(context),
                      child: Container(
                        height: 55,
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                          color: accentColor,
                        ),
                        child: Center(
                          child: Text(
                            "Info",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
