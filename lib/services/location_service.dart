import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/models/direction_response_model.dart';
import 'package:instaport_rider/models/location_model.dart';

const String key = "AIzaSyCQb159dbqJypdIO1a1o0v_mNgM5eFqVAo";

class LocationService {
  AppController appController = Get.put(AppController());
  Future<DistanceApiResponse> fetchDistance(LatLng src, LatLng dest) async {
    String endpoint =
        'https://maps.googleapis.com/maps/api/distancematrix/json?destinations=${dest.latitude},${dest.longitude}&origins=${src.latitude},${src.longitude}&key=AIzaSyCQb159dbqJypdIO1a1o0v_mNgM5eFqVAo';
    final response = await http.get(Uri.parse(endpoint));

    if (response.statusCode == 200) {
      return DistanceApiResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load places');
    }
  }

  Future<DirectionDetailsInfo> fetchDirections(
      double srclat, double srclng, double destlat, double destlng) async {
    String endpoint =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$srclat,$srclng&destination=$destlat,$destlng&key=AIzaSyCQb159dbqJypdIO1a1o0v_mNgM5eFqVAo';
    var response = await http.get(Uri.parse(endpoint));
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      DirectionDetailsInfo directionInfo = DirectionDetailsInfo();
      directionInfo.e_points = data["routes"][0]["overview_polyline"]["points"];
      directionInfo.distance_text =
          data["routes"][0]["legs"][0]["distance"]["text"];
      directionInfo.distance_value =
          data["routes"][0]["legs"][0]["distance"]["value"];
      directionInfo.duration_value =
          data["routes"][0]["legs"][0]["duration"]["value"];
      directionInfo.duration_text =
          data["routes"][0]["legs"][0]["duration"]["text"];
      return directionInfo;
    } else {
      throw Exception('Failed to load places');
    }
  }
}
