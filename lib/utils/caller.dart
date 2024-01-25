  // ignore_for_file: deprecated_member_use

  import 'package:url_launcher/url_launcher.dart';

void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }