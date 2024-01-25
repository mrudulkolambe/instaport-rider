// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/components/display_input.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/order_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class TrackOrderDetails extends StatefulWidget {
  final Orders data;

  const TrackOrderDetails({super.key, required this.data});

  @override
  State<TrackOrderDetails> createState() => _TrackOrderDetailsState();
}

final _storage = GetStorage();

class ExpansionPanelItem {
  ExpansionPanelItem({
    required this.title,
    required this.subtitle,
    required this.phonenumber,
    required this.instructions,
    this.isExpanded = false,
  });

  String title;
  String subtitle;
  bool isExpanded;
  String phonenumber;
  String instructions;
}

class _TrackOrderDetailsState extends State<TrackOrderDetails>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool paymentpanel = false;
  List<ExpansionPanelItem> lists = [];
  List<ExpansionPanelItem> droplocationslists = [];
  Orders? order;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      order = widget.data;
    });
    _tabController = TabController(length: 3, vsync: this);
    lists.add(
      ExpansionPanelItem(
        title: "Pickup",
        subtitle: order!.pickup.address,
        phonenumber: order!.pickup.phone_number,
        instructions: order!.pickup.instructions,
      ),
    );
    lists.add(
      ExpansionPanelItem(
        title: "Drop",
        subtitle: order!.drop.address,
        phonenumber: order!.drop.phone_number,
        instructions: order!.drop.instructions,
      ),
    );
    var data = List.from(order!.droplocations).map<ExpansionPanelItem>((e) {
      return ExpansionPanelItem(
        title: "Drop Point",
        subtitle: e.address,
        phonenumber: e.phone_number,
        instructions: e.instructions,
      );
    }).toList();
    setState(() {
      droplocationslists = data;
    });
  }

  void handleConfirm(String address) async {
    final token = await _storage.read("token");
    var data = await http.get(Uri.parse("$apiUrl/order/customer/${order!.id}"));
    var orderData = OrderResponse.fromJson(jsonDecode(data.body));
    var filterOrder = orderData.order.orderStatus.where((element) {
      return element.message == address;
    });
    print({
      "status": "processing",
      "orderStatus": [
        ...orderData.order.orderStatus.map((e) {
          return e.toJson();
        }).toList(),
        {
          "timestamp": DateTime.now().millisecondsSinceEpoch,
          "message": address,
        }
      ]
    });
    if (filterOrder.isEmpty) {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      var request = http.Request(
          'PATCH', Uri.parse('$apiUrl/order/orderstatus/${order!.id}'));
      request.body = json.encode({
        "status": "processing",
        "orderStatus": [
          ...orderData.order.orderStatus.map((e) {
            return e.toJson();
          }).toList(),
          {
            "timestamp": DateTime.now().millisecondsSinceEpoch,
            "message": address,
          }
        ]
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var json = await response.stream.bytesToString();
        var updatedOrderData = OrderResponse.fromJson(jsonDecode(json));
        Get.back();
        Get.back();
        Get.snackbar("Message", updatedOrderData.message);
      } else {
        Get.back();
        Get.snackbar("Message", response.reasonPhrase!);
      }
    } else {
      Get.back();
      Get.snackbar("Message", "Unable to update");
    }
  }

  void handleConfirmStatus(String task, String address) {
    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width - 50,
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 15.0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Confirm",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Are you sure you've completed $task?",
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(
              height: 20,
            ),
            loading
                ? const SpinKitFadingCircle(
                    color: accentColor,
                    size: 20,
                  )
                : Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => task == "order"
                              ? handleOrderComplete()
                              : handleConfirm(address),
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  width: 2, color: Colors.transparent),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Center(
                              child: Text(
                                "Yes",
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
                              horizontal: 10,
                              vertical: 12,
                            ),
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
    ));
  }

  void handleOrderComplete() async {
    final token = await _storage.read("token");
    var data = await http.get(Uri.parse("$apiUrl/order/customer/${order!.id}"));
    var orderData = OrderResponse.fromJson(jsonDecode(data.body));
    if (orderData.order.orderStatus.length ==
        2 + orderData.order.droplocations.length) {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      var request = http.Request(
          'PATCH', Uri.parse('$apiUrl/order/completed/${order!.id}'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var json = await response.stream.bytesToString();
        var updatedOrderData = OrderResponse.fromJson(jsonDecode(json));
        Get.back();
        Get.back();
        Get.snackbar("Message", updatedOrderData.message);
      } else {
        Get.back();
        Get.snackbar("Message", response.reasonPhrase!);
      }
    } else {
      Get.back();
      Get.snackbar("Message", "Complete all the dropings first.");
    }
  }

  List<Widget> handleDropContainers() {
    List<Widget> dropContainers = [];
    if (order!.droplocations.isNotEmpty) {
      dropContainers = List.from(order!.droplocations).asMap().entries.map((e) {
        return Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () => handleConfirmStatus(
                "drop",
                e.value.address,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: accentColor,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Drop Completed",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (order!.orderStatus.length > 2 &&
                            e.value.address ==
                                widget.data.orderStatus[2 + e.key].message)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.value.address,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            softWrap: false,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList();
    }
    return dropContainers;
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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
          title: "Info #${order == null ? "" : order!.id.substring(18)}",
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 2.5,
              enableFeedback: false,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              labelColor: Colors.black,
              indicatorColor: accentColor,
              unselectedLabelColor: Colors.black26,
              tabs: const [
                Tab(text: 'Details'), // Tab 1: Details
                Tab(text: 'Track'), // Tab 2: Breakdown
                Tab(text: 'Breakdown'), // Tab 3: Breakdown
              ],
            ),
            Expanded(
              child: SizedBox(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Text(
                                "Rs. ${order!.amount.toPrecision(1).toString()}",
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
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
                                "Weight: ",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                width: 2,
                              ),
                              Text(
                                order!.parcel_weight,
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
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
                                order!.package,
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
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
                                order!.customer.fullname,
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
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
                                  order!.customer.mobileno,
                                ),
                                child: Text(
                                  order!.customer.mobileno,
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            child: ExpansionPanelList(
                              expansionCallback: (int index, bool isExpanded) {
                                setState(() {
                                  // _data[index].isExpanded = !isExpanded;
                                });
                              },
                              expandedHeaderPadding: const EdgeInsets.all(0),
                              dividerColor: Colors.transparent,
                              materialGapSize: 10,
                              children: lists.map<ExpansionPanel>(
                                  (ExpansionPanelItem item) {
                                return ExpansionPanel(
                                  backgroundColor:
                                      const Color.fromRGBO(255, 245, 157, 1),
                                  headerBuilder:
                                      (BuildContext context, bool isExpanded) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: ListTile(
                                        splashColor: Colors.transparent,
                                        onTap: () {
                                          setState(() {
                                            item.isExpanded = !item.isExpanded;
                                          });
                                        },
                                        title: Text(item.title),
                                      ),
                                    );
                                  },
                                  body: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    // title: Text(item.subtitle),
                                    child: Column(
                                      children: [
                                        DisplayInput(
                                          label: "${item.title} Point",
                                          value: item.subtitle,
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        DisplayInput(
                                          label: "Phone No",
                                          value: item.phonenumber,
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        DisplayInput(
                                          label: "Instructions",
                                          value: item.instructions,
                                        ),
                                      ],
                                    ),
                                  ),
                                  isExpanded: item.isExpanded,
                                );
                              }).toList(),
                            ),
                          ),
                          ExpansionPanelList(
                            expansionCallback: (int index, bool isExpanded) {
                              setState(() {
                                // _data[index].isExpanded = !isExpanded;
                              });
                            },
                            expandedHeaderPadding: const EdgeInsets.all(0),
                            dividerColor: Colors.transparent,
                            materialGapSize: 10,
                            children: droplocationslists
                                .map<ExpansionPanel>((ExpansionPanelItem item) {
                              return ExpansionPanel(
                                backgroundColor:
                                    const Color.fromRGBO(255, 245, 157, 1),
                                headerBuilder:
                                    (BuildContext context, bool isExpanded) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    child: ListTile(
                                      splashColor: Colors.transparent,
                                      onTap: () {
                                        setState(() {
                                          item.isExpanded = !item.isExpanded;
                                        });
                                      },
                                      title: Text(item.title),
                                    ),
                                  );
                                },
                                body: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      DisplayInput(
                                        label: "${item.title} Point",
                                        value: item.subtitle,
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      DisplayInput(
                                        label: "Phone No",
                                        value: item.phonenumber,
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      DisplayInput(
                                        label: "Instructions",
                                        value: item.instructions,
                                      ),
                                    ],
                                  ),
                                ),
                                isExpanded: item.isExpanded,
                              );
                            }).toList(),
                          ),
                          if (order!.payment_method == "cod")
                            ExpansionPanelList(
                              expansionCallback:
                                  (int index, bool isExpanded) {},
                              expandedHeaderPadding: const EdgeInsets.all(0),
                              dividerColor: Colors.transparent,
                              materialGapSize: 10,
                              children: [
                                ExpansionPanel(
                                  headerBuilder: (context, isExpanded) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: ListTile(
                                        splashColor: Colors.transparent,
                                        onTap: () {
                                          setState(() {
                                            paymentpanel = !paymentpanel;
                                          });
                                        },
                                        title: const Text("Payment Addess"),
                                      ),
                                    );
                                  },
                                  isExpanded: paymentpanel,
                                  body: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        DisplayInput(
                                          label: "Payment Address",
                                          value: widget
                                              .data.payment_address!.address,
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        DisplayInput(
                                          label: "Phone No",
                                          value: order!
                                              .payment_address!.phone_number,
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        DisplayInput(
                                          label: "Instructions",
                                          value: order!
                                              .payment_address!.instructions,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                            onTap: () => handleConfirmStatus(
                              "pickup",
                              order!.pickup.address,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: accentColor,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Pickup Completed",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (order!.orderStatus.isNotEmpty &&
                                          order!.pickup.address ==
                                              widget
                                                  .data.orderStatus[0].message)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          order!.pickup.address,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          softWrap: false,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                            onTap: () => handleConfirmStatus(
                              "drop",
                              order!.drop.address,
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: accentColor,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Drop Completed",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (order!.orderStatus.length > 1 &&
                                          order!.drop.address ==
                                              widget
                                                  .data.orderStatus[1].message)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          order!.drop.address,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          softWrap: false,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ...handleDropContainers(),
                          const SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                            onTap: () => handleConfirmStatus("order", ""),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: accentColor,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Order Completed",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Complete the order",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          softWrap: false,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Instaport Commission",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "- ₹${(order!.amount * (order!.commission/100)).toPrecision(1).toString()}",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 7,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Rider Charge",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "+ ₹${(order!.amount * ((100 - order!.commission)/100)).toPrecision(1).toString()}",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 7,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Parcel Charge",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "₹${(order!.amount).toPrecision(1).toString()}",
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
