import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:instaport_rider/controllers/user.dart';
import 'package:instaport_rider/firebase_messaging/firebase_messaging.dart';
import 'package:instaport_rider/screens/wallet.dart';

class BillDeskPayment extends StatefulWidget {
  final String url;

  const BillDeskPayment({super.key, required this.url});

  @override
  State<BillDeskPayment> createState() => _BillDeskPaymentState();
}


class _BillDeskPaymentState extends State<BillDeskPayment> {
  final RiderController riderController = Get.put(RiderController());
  InAppWebViewController? webView;
  String apptoken = "";

  void _setupJavaScriptHandler() {
    if (webView != null) {
      // Set up JavaScript handler to listen for messages from the WebView
      webView!.addJavaScriptHandler(
        handlerName: 'backfunction',
        callback: (args) {
          _performActionInFlutter();
        },
      );
    }
  }

  void _performActionInFlutter() {
    FirebaseMessagingAPI().localNotificationsApp(RemoteNotification(
      title: "Transaction successfull",
      body: "Floating amount of your account has been cleared!",
    ));
    Get.to(() => const Wallet());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.url),
              ),
              shouldOverrideUrlLoading: (controller, request) async {
                return NavigationActionPolicy.ALLOW;
              },
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  supportZoom: false,
                  clearCache: true,
                  javaScriptEnabled: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  mediaPlaybackRequiresUserGesture: false,
                ),
                android: AndroidInAppWebViewOptions(
                  mixedContentMode:
                      AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  thirdPartyCookiesEnabled: true,
                ),
                ios: IOSInAppWebViewOptions(
                  allowsInlineMediaPlayback: true,
                  allowsAirPlayForMediaPlayback: true,
                  allowsBackForwardNavigationGestures: true,
                  allowsLinkPreview: true,
                  isFraudulentWebsiteWarningEnabled: true,
                  suppressesIncrementalRendering: false,
                ),
              ),
              onWebViewCreated: (controller) {
                webView = controller;
                _setupJavaScriptHandler();
              },
              onLoadStart: (controller, url) {
                setState(() {
                });
              },
              onLoadError: (controller, url, code, message) {
                print("message: $message");
              },
              onConsoleMessage: (controller, consoleMessage) {
                print("Message: ${consoleMessage.message}");
              },
              onLoadStop: (controller, url) {
                setState(() {
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
