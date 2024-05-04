import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:instaport_rider/controllers/app.dart';
import 'package:instaport_rider/models/address_model.dart';
import 'package:instaport_rider/models/direction_response_model.dart';
import 'package:instaport_rider/models/location_model.dart';

const String key = "AIzaSyDz11oR0kxuuNQFW9RqQYJ5NnOsfi_OGZ4";

class LocationService {
  AppController appController = Get.put(AppController());
  Future<double> fetchDistance(LatLng src, LatLng dest) async {
    String endpoint =
        'https://maps.googleapis.com/maps/api/distancematrix/json?destinations=${dest.latitude},${dest.longitude}&origins=${src.latitude},${src.longitude}&key=$key';
    final response = await http.get(Uri.parse(endpoint));

    if (response.statusCode == 200) {
      return DistanceApiResponse.fromJson(jsonDecode(response.body)).rows[0].elements[0].distance == null ? 0.0 : DistanceApiResponse.fromJson(jsonDecode(response.body)).rows[0].elements[0].distance!.value! + 0.0 ;
    } else {
      throw Exception('Failed to load places');
    }
  }

  Future<DirectionDetailsInfo> fetchDirections(double srclat, double srclng,
      double destlat, double destlng, List<Address> droplocations) async {
    String endpoint = "";
    try {
      if (droplocations.isEmpty) {
        endpoint =
            'https://maps.googleapis.com/maps/api/directions/json?origin=$srclat,$srclng&destination=$destlat,$destlng&key=$key';
      } else {
        final List<String> waypoints = [];
        waypoints.add('$destlat,$destlng');
        for (var i = 0; i < droplocations.length; i++) {
          waypoints.add(
              '${droplocations[i].latitude},${droplocations[i].longitude}');
        }
        waypoints.removeLast();
        var waypointsString = waypoints.join('|');
        endpoint =
            'https://maps.googleapis.com/maps/api/directions/json?origin=$srclat,$srclng&destination=${droplocations.last.latitude},${droplocations.last.longitude}&waypoints=optimize:true|$waypointsString&key=$key';
      }

      var response = await http.get(Uri.parse(endpoint));
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        DirectionDetailsInfo directionInfo = DirectionDetailsInfo();
        directionInfo.e_points =
            data["routes"][0]["overview_polyline"]["points"];
        directionInfo.distance_text =
            data["routes"][0]["legs"][0]["distance"]["text"];
        directionInfo.distance_value =
            data["routes"][0]["legs"][0]["distance"]["value"] + 0.0;
        directionInfo.duration_value =
            data["routes"][0]["legs"][0]["duration"]["value"] + 0.0;
        directionInfo.duration_text =
            data["routes"][0]["legs"][0]["duration"]["text"];
        return directionInfo;
      } else {
        throw Exception('Failed to load places');
      }
    } catch (e) {
      throw Exception("Error This: $e");
    }
  }
}
