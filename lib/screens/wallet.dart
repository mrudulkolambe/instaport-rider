import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/components/bottomnavigationbar.dart';
import 'package:instaport_rider/components/transaction_card.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/constants/svgs.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/main.dart';
import 'package:instaport_rider/models/transaction_model.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/screens/billdesk.dart';
import 'package:instaport_rider/utils/toast_manager.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  List<SingleTransaction> transactions = [];
  late Timer _timer;
  bool loading = true;
  bool requestLoading = false;
  final _storage = GetStorage();
  RiderController riderController = Get.put(RiderController());

  @override
  void initState() {
    super.initState();
    handleFetch(true);
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      handleFetch(false);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  void handleFetch(bool load) async {
    try {
      setState(() {
        loading = load;
      });
      final token = await _storage.read("token");
      final response = await http.get(Uri.parse("$apiUrl/rider/transactions"),
          headers: {'Authorization': 'Bearer $token'});
      final data = await http.get(Uri.parse('$apiUrl/rider/'),
          headers: {'Authorization': 'Bearer $token'});
      final userData = RiderDataResponse.fromJson(jsonDecode(data.body));
      riderController.updateRider(userData.rider);
      if (response.statusCode == 200) {
        RiderTransactions transactionResponse =
            RiderTransactions.fromJson(jsonDecode(response.body));
        setState(() {
          loading = false;
          transactions = transactionResponse.transactions.reversed.toList();
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void payMoney() async {
    final token = await _storage.read("token");
    print("https://instaport-transactions.vercel.app/rider-dues.html?token=$token&amount=${-riderController.rider.wallet_amount}");
    Get.to(
      () => BillDeskPayment(
        url: "https://instaport-transactions.vercel.app/rider-dues.html?token=$token&amount=${-riderController.rider.wallet_amount}",
      ),
    );
  }

  void requestMoney() async {
    try {
      final token = await _storage.read("token");
      setState(() {
        requestLoading = true;
      });

      var response = await http.post(
        Uri.parse("$apiUrl/rider/request-money"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      var data = RiderDataResponse.fromJson(jsonDecode(response.body));
      ToastManager.showToast(data.message);
      setState(() {
        requestLoading = false;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const CustomAppBar(
          title: "Wallet",
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              GetBuilder<RiderController>(
                  init: RiderController(),
                  builder: (ridercontroller) {
                    return Container(
                      height: 200,
                      width: MediaQuery.of(context).size.width - 50,
                      decoration: BoxDecoration(
                        color: accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10.0,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(255, 226, 76, 0.65),
                            accentColor,
                            Color.fromRGBO(247, 192, 0, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Main Balance",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 0,
                                ),
                                Text(
                                  "₹${ridercontroller.rider.wallet_amount.toPrecision(2)}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "Requested: ₹${ridercontroller.rider.requestedAmount.toPrecision(2)}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                ridercontroller.rider.wallet_amount < 0
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: payMoney,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  50 -
                                                  45,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 30,
                                                  vertical: 10,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Pay",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: requestMoney,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  50 -
                                                  45,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 30,
                                                  vertical: 10,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Request Money",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
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
                          ],
                        ),
                      ),
                    );
                  }),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Text(
                    "Latest Transactions",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              loading
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height - 300 - 150,
                      width: MediaQuery.of(context).size.width - 50,
                      child: const Center(
                        child: SpinKitFadingCircle(
                          color: accentColor,
                          size: 25,
                        ),
                      ),
                    )
                  : transactions.isEmpty
                      ? SizedBox(
                          height:
                              MediaQuery.of(context).size.height - 300 - 150,
                          width: MediaQuery.of(context).size.width - 50,
                          child: Center(
                            child: SvgPicture.string(nodatafound),
                          ),
                        )
                      : SizedBox(
                          height:
                              MediaQuery.of(context).size.height - 300 - 150,
                          width: MediaQuery.of(context).size.width - 50,
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) => TransactionCard(
                              data: transactions[index],
                            ),
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: 10,
                            ),
                            itemCount: transactions.length,
                          ),
                        )
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
