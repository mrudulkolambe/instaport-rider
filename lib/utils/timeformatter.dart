import 'package:intl/intl.dart';

String readTimestamp(int timestamp) {
  var format = DateFormat('d-MMM-yyyy, HH:mm');
  var date = DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
  return format.format(date);
}
