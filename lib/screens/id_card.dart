import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instaport_rider/components/appbar.dart';
import 'package:instaport_rider/constants/colors.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/utils/timeformatter.dart';
import 'package:instaport_rider/utils/toast_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
// import 'package:gallery_saver_updated/gallery_saver.dart';

class IDCard extends StatefulWidget {
  const IDCard({super.key});

  @override
  State<IDCard> createState() => _IDCardState();
}

class _IDCardState extends State<IDCard> {
  WidgetsToImageController controller = WidgetsToImageController();
  final RiderController riderController = Get.put(RiderController());
  bool loading = false;
  Uint8List? bytes;

  Future<void> _saveImage(Uint8List bytes) async {
    try {
      if (await Permission.manageExternalStorage.request().isGranted) {
        final Directory directory = await getTemporaryDirectory();
        final file = await File("${directory.path}/ID.png").writeAsBytes(bytes);
        print(file.path);
        await Gal.putImage(file.path);
        // await GallerySaver.saveImage(file.path);
        // final String downloadsDirPath = '${directory!.path}/downloads';

        // final Directory downloadsDir = Directory(downloadsDirPath);
        // if (!await downloadsDir.exists()) {
        //   await downloadsDir.create(recursive: true);
        // }

        // final filePath =
        //     '${downloadsDir.toString().replaceAll("'", "")}/ID_card.png';
        // final File file = File(filePath);
        // await file.writeAsBytes(bytes);

        // // Write the bytes to the file.
        // // await file.writeAsBytes(bytes);

        // if (await file.exists()) {
        //   print('Image successfully saved at: ${file.path}');
        // } else {
        //   print('Image not found at: ${file.path}');
        // }
        ToastManager.showToast('Image saved to downloads');
      } else {
        ToastManager.showToast('Storage permission denied');
      }
    } catch (e) {
      print('Error saving image: $e');
      ToastManager.showToast('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const CustomAppBar(
          title: "Instaport ID",
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            height: 40,
          ),
          WidgetsToImage(
            controller: controller,
            child: IDCardWidget(riderController: riderController),
          ),
          const SizedBox(
            height: 25,
          ),
          GestureDetector(
            onTap: () async {
              final bytes = await controller.capture();
              _saveImage(bytes!);
            },
            child: Container(
              height: 55,
              width: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: accentColor,
              ),
              child: Center(
                child: Text(
                  "Download ID",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IDCardWidget extends StatefulWidget {
  final RiderController riderController;
  const IDCardWidget({super.key, required this.riderController});

  @override
  State<IDCardWidget> createState() => _IDCardWidgetState();
}

class _IDCardWidgetState extends State<IDCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SvgPicture.asset(
            "assets/id_card.svg",
            height: MediaQuery.of(context).size.width * 1.2,
            width: MediaQuery.of(context).size.width * 1.2,
          ),
        ),
        Positioned(
          top: 110,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(
                        widget.riderController.rider.image!.url,
                      ),
                      radius: 70,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  widget.riderController.rider.fullname,
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  "ID: #${widget.riderController.rider.id.substring(18)}",
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  "Phone: ${widget.riderController.rider.mobileno}",
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  "Delivery partner at Instaport",
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "Joined at: ${readTimestampAsDate(widget.riderController.rider.timestamp)}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ],
          ),
        )
      ],
    );
  }
}
