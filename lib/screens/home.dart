// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/components/order_card.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/constants/svgs.dart';
import 'package:instaport_rider/controllers/app.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/services/background_location_service.dart';
import 'package:instaport_rider/services/location_service.dart';
import 'package:instaport_rider/utils/toast_manager.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

final _storage = GetStorage();

class _HomeState extends State<Home> with TickerProviderStateMixin {
  AppController appController = Get.put(AppController());
  RiderController riderController = Get.put(RiderController());
  List<Orders> orders = [];
  List<Orders> ordersSearch = [];
  bool loading = false;
  late TabController _tabController;
  Map<String, bool> selectedStates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (riderController.rider.status != "offline") {
      handlePrefetch();
    }
  }

  void onSelectionChanged(String orderId, bool isSelected) {
    setState(() {
      selectedStates[orderId] = isSelected;
    });
  }

  int getTotalSelected() {
    return selectedStates.values.where((isSelected) => isSelected).length;
  }

  void handlePrefetch() async {
    var ordersResponse = await getPastOrders();
    setState(() {
      orders = ordersResponse;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  Future<List<Orders>> getPastOrders() async {
    final token = await _storage.read("token");
    setState(() {
      loading = true;
    });
    const String url = '$apiUrl/order/riders';
    print(url);
    print(token);
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = AllOrderResponse.fromJson(json.decode(response.body));
    var sortedOrders = await sortOrders(data.orders);
    final riderData = await http.get(
      Uri.parse('$apiUrl/rider/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final userData = RiderDataResponse.fromJson(jsonDecode(riderData.body));
    riderController.updateRider(userData.rider);
    if (riderController.rider.isDue!) {
      ToastManager.showToast("Clear the dues! Only online orders are visible");
    }
    setState(() {
      ordersSearch = sortedOrders;
      orders = sortedOrders;
      loading = false;
    });
    return sortedOrders;
  }

  Future<List<Orders>> sortOrders(List<Orders> ordersData) async {
    Future.forEach(ordersData, (Orders order) async {
      var data = await LocationService().fetchDistance(
        LatLng(appController.currentposition.value.target.latitude,
            appController.currentposition.value.target.longitude),
        LatLng(order.pickup.latitude, order.pickup.longitude),
      );
    });
    ordersData.sort((a, b) {
      return a.distance.compareTo(b.distance);
    });
    return ordersData.where((element) {
      return element.distance <= 10000;
    }).toList();
  }

Widget _buildTabWithRefreshIndicator(List<Orders> tabOrders) {
  return RefreshIndicator(
    onRefresh: () => getPastOrders(),
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      children: tabOrders.isEmpty
          ? [
              Center(child: SvgPicture.string(nodatafound)),
            ]
          : tabOrders.map((order) {
              return OrderCard(
                data: order,
                modal: true,
                isSelected: false,
              );
            }).toList(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 60,
          surfaceTintColor: Colors.white,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Text(
            "Orders",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 1.5,
            enableFeedback: false,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            labelColor: Colors.black,
            indicatorColor: accentColor,
            unselectedLabelColor: Colors.black26,
            tabs: <Widget>[
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Available",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(
                      width: 2,
                    ),
                    Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Text(
                          orders
                              .where(
                                (element) =>
                                    element.rider == null &&
                                    element.status == "new",
                              )
                              .length
                              .toString(),
                          style: GoogleFonts.poppins(fontSize: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Active",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(
                      width: 2,
                    ),
                    Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Text(
                          orders
                              .where(
                                (element) =>
                                    element.rider != null &&
                                    element.status == "processing",
                              )
                              .length
                              .toString(),
                          style: GoogleFonts.poppins(fontSize: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Completed",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(
                      width: 2,
                    ),
                    Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Text(
                          orders
                              .where(
                                (element) =>
                                    element.rider != null &&
                                    element.status == "delivered",
                              )
                              .length
                              .toString(),
                          style: GoogleFonts.poppins(fontSize: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(),
        body: riderController.rider.status == "offline"
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/offline.svg",
                        width: MediaQuery.of(context).size.width * 0.8,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                ],
              )
            : SafeArea(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: SizedBox(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTabWithRefreshIndicator(
                              orders
                                  .where((element) =>
                                      element.rider == null &&
                                      element.status == "new")
                                  .toList(),
                            ),
                            _buildTabWithRefreshIndicator(
                              orders
                                  .where((element) =>
                                      element.rider != null &&
                                      element.status == "processing")
                                  .toList(),
                            ),
                            _buildTabWithRefreshIndicator(
                              orders
                                  .where((element) =>
                                      element.rider != null &&
                                      element.status == "delivered")
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
