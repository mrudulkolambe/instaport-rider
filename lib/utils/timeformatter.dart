import 'package:intl/intl.dart';

String readTimestamp(int timestamp) {
  var format = DateFormat('d-MMM-yyyy, HH:mm');
  var date = DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
  return format.format(date);
}
String readTimestampAsTime(int timestamp) {
  var format = DateFormat('HH:mm');
  var date = DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
  return format.format(date);
}

String formatMilliseconds(int milliseconds) {
  int totalSeconds = (milliseconds / 1000).round(); // Convert milliseconds to seconds
  int hours = totalSeconds ~/ 3600; // Get hours
  int minutes = (totalSeconds % 3600) ~/ 60; // Get minutes
  int remainingSeconds = totalSeconds % 60; // Get remaining seconds

  String hoursString = (hours < 10) ? '0$hours' : '$hours';
  String minutesString = (minutes < 10) ? '0$minutes' : '$minutes';
  String secondsString = (remainingSeconds < 10) ? '0$remainingSeconds' : '$remainingSeconds';

  return '$hoursString:$minutesString:$secondsString';
}
