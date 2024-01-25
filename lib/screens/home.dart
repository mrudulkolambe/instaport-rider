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
import 'package:instaport_rider/services/location_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    handlePrefetch();
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
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    final data = AllOrderResponse.fromJson(json.decode(response.body));
    var sortedOrders = await sortOrders(data.orders);
    final riderData = await http.get(Uri.parse('$apiUrl/rider/'),
        headers: {'Authorization': 'Bearer $token'});
    final userData = RiderDataResponse.fromJson(jsonDecode(riderData.body));
    riderController.updateRider(userData.rider);
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
      order.distance = data.rows[0].elements[0].distance != null
          ? data.rows[0].elements[0].distance!.value!
          : 0;
    });
    ordersData.sort((a, b) {
      return a.distance.compareTo(b.distance);
    });
    return ordersData.where((element) {
      return element.distance <= 10000;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Text(
            "Orders",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 2.5,
            enableFeedback: false,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            labelColor: Colors.black,
            indicatorColor: accentColor,
            unselectedLabelColor: Colors.black26,
            tabs: const <Widget>[
              Tab(
                text: "Available",
              ),
              Tab(
                text: "Active",
              ),
              Tab(
                text: "Completed",
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(),
        body: RefreshIndicator(
          onRefresh: () => getPastOrders(),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 30 - 200,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        loading
                            ? const SpinKitFadingCircle(
                                color: accentColor,
                              )
                            : orders
                                    .where(
                                      (element) =>
                                          element.rider == null &&
                                          element.status == "new",
                                    )
                                    .isEmpty
                                ? Center(
                                    child: SvgPicture.string(nodatafound),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 25.0,
                                    ),
                                    child: ListView.separated(
                                        physics: const BouncingScrollPhysics(),
                                        scrollDirection: Axis.vertical,
                                        itemBuilder: (context, index) {
                                          return OrderCard(
                                            data: orders
                                                .where(
                                                  (element) =>
                                                      element.rider == null &&
                                                      element.status == "new",
                                                )
                                                .toList()[index],
                                            modal: true,
                                          );
                                        },
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(
                                              height: 10,
                                            ),
                                        itemCount: orders
                                            .where(
                                              (element) =>
                                                  element.rider == null &&
                                                  element.status == "new",
                                            )
                                            .length),
                                  ),
                        loading
                            ? const SpinKitFadingCircle(
                                color: accentColor,
                              )
                            : orders
                                    .where(
                                      (element) =>
                                          element.rider != null &&
                                          element.status == "processing",
                                    )
                                    .isEmpty
                                ? Center(
                                    child: SvgPicture.string(nodatafound),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 25,
                                    ),
                                    child: ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      scrollDirection: Axis.vertical,
                                      itemBuilder: (context, index) {
                                        return OrderCard(
                                          data: orders
                                              .where(
                                                (element) =>
                                                    element.rider != null &&
                                                    element.status ==
                                                        "processing",
                                              )
                                              .toList()[index],
                                          modal: true,
                                        );
                                      },
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(
                                        height: 10,
                                      ),
                                      itemCount: orders
                                          .where((element) {
                                            return element.rider != null &&
                                                element.status == "processing";
                                          })
                                          .toList()
                                          .length,
                                    ),
                                  ),
                        loading
                            ? const SpinKitFadingCircle(
                                color: accentColor,
                              )
                            : orders
                                    .where(
                                      (element) =>
                                          element.rider != null &&
                                          element.status == "delivered",
                                    )
                                    .isEmpty
                                ? Center(
                                    child: SvgPicture.string(nodatafound),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 25,
                                    ),
                                    child: ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      scrollDirection: Axis.vertical,
                                      itemBuilder: (context, index) {
                                        return OrderCard(
                                          data: orders
                                              .where(
                                                (element) =>
                                                    element.rider != null &&
                                                    element.status ==
                                                        "delivered",
                                              )
                                              .toList()[index],
                                          modal: true,
                                        );
                                      },
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(
                                        height: 10,
                                      ),
                                      itemCount: orders
                                          .where((element) {
                                            return element.rider != null &&
                                                element.status == "delivered";
                                          })
                                          .toList()
                                          .length,
                                    ),
                                  ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
