import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/constants/svgs.dart';
import 'package:instaport_rider/controllers/user.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                                  height: 10,
                                ),
                                Text(
                                  "₹${ridercontroller.rider.wallet_amount}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 30,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      // onTap: () async {
                                      //   final token =
                                      //       await _storage.read("token");
                                      //   Get.to(() => WalletTopup(
                                      //         url:
                                      //             "https://instaport-transactions.vercel.app/?token=$token",
                                      //       ));
                                      // },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                50 -
                                                45,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 30,
                                            vertical: 10,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Request Money",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
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
              false
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
                  : true
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
                            itemBuilder: (context, index) => null,
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: 10,
                            ),
                            itemCount: 0,
                          ),
                        )
            ],
          ),
        ),
      ),
    );
  }
}
