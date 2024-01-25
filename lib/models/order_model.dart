// ignore_for_file: non_constant_identifier_names

import 'package:instaport_rider/models/address_model.dart';
import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/models/user_model.dart';

class AllOrderResponse {
  bool error;
  String message;
  List<Orders> orders;

  AllOrderResponse({
    required this.error,
    required this.message,
    required this.orders,
  });

  factory AllOrderResponse.fromJson(dynamic json) {
    final items = List.from(json["order"]).map((e) {
      return Orders.fromJson(e);
    }).toList();
    final error = json['error'] as bool;
    final message = json['message'] as String;
    return AllOrderResponse(error: error, message: message, orders: items);
  }
}

class OrderResponse {
  bool error;
  String message;
  Orders order;

  OrderResponse({
    required this.error,
    required this.message,
    required this.order,
  });

  factory OrderResponse.fromJson(dynamic json) {
    final error = json['error'] as bool;
    final message = json['message'] as String;
    final order = Orders.fromJson(json['order']);
    return OrderResponse(error: error, message: message, order: order);
  }
}

class OrderStatus {
  int timestamp;
  String message;

  OrderStatus({
    required this.timestamp,
    required this.message,
  });

  factory OrderStatus.fromJson(dynamic json) {
    final timestamp = json['timestamp'] as int;
    final message = json['message'] as String;
    return OrderStatus(
      timestamp: timestamp,
      message: message,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "timestamp": timestamp,
      "message": message,
    };
  }
}

class Orders {
  Address pickup;
  Address drop;
  List<Address> droplocations;
  String id;
  String delivery_type;
  String parcel_weight;
  String phone_number;
  bool notify_sms;
  bool courier_bag;
  String vehicle;
  String status;
  String payment_method;
  User customer;
  String package;
  int time_stamp;
  int parcel_value;
  double amount;
  double distance;
  double commission;
  Rider? rider;
  Address? payment_address;
  List<OrderStatus> orderStatus;

  Orders({
    required this.pickup,
    required this.drop,
    required this.id,
    required this.delivery_type,
    required this.parcel_weight,
    required this.droplocations,
    required this.phone_number,
    required this.notify_sms,
    required this.courier_bag,
    required this.vehicle,
    required this.status,
    required this.payment_method,
    required this.customer,
    required this.package,
    required this.time_stamp,
    required this.parcel_value,
    required this.amount,
    required this.distance,
    required this.commission,
    required this.orderStatus,
    this.rider,
    this.payment_address,
  });

  factory Orders.fromJson(dynamic json) {
// Future<void> fetchDistance(double lat, double lng) async {
//     String endpoint =
//         'https://maps.googleapis.com/maps/api/distancematrix/json?destinations=${lat},${lng}&origins=${appController.currentposition.value.target.latitude},${appController.currentposition.value.target.longitude}&key=AIzaSyCQb159dbqJypdIO1a1o0v_mNgM5eFqVAo';
//     final response = await http.get(Uri.parse(endpoint));

//     if (response.statusCode == 200) {
//       return DistanceApiResponse.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Failed to load places');
//     }
//   }
    final pickup = Address.fromJson(json['pickup']);
    final drop = Address.fromJson(json['drop']);
    final orderStatus = List.from(json["orderStatus"]).map((e) {
      return OrderStatus.fromJson(e);
    }).toList();
    final droplocations = List.from(json["droplocations"]).map((e) {
      return Address.fromJson(e);
    }).toList();
    final distance = 0.0;
    final id = json['_id'] as String;
    final delivery_type = json['delivery_type'] as String;
    final parcel_weight = json['parcel_weight'] as String;
    final phone_number = json['phone_number'] as String;
    final notify_sms = json['notify_sms'] as bool;
    final courier_bag = json['courier_bag'] as bool;
    final vehicle = json['vehicle'] as String;
    final status = json['status'] as String;
    final payment_method = json['payment_method'] as String;
    final customer = User.fromJson(json['customer']);
    final package = json['package'] as String;
    final time_stamp = json['time_stamp'] as int;
    final amount = json['amount'] + 0.0 as double;
    final commission = json['commission'] + 0.0 as double;
    final parcel_value = json['parcel_value'];
    final payment_address = json['payment_address'] == null
        ? null
        : Address.fromJson(json['payment_address']);

    return Orders(
      pickup: pickup,
      drop: drop,
      id: id,
      delivery_type: delivery_type,
      parcel_weight: parcel_weight,
      phone_number: phone_number,
      notify_sms: notify_sms,
      courier_bag: courier_bag,
      vehicle: vehicle,
      commission: commission,
      status: status,
      payment_method: payment_method,
      customer: customer,
      package: package,
      time_stamp: time_stamp,
      parcel_value: parcel_value,
      amount: amount,
      distance: distance,
      orderStatus: orderStatus,
      rider: json["rider"] == null
          ? null
          : Rider.fromJson(
              json["rider"],
            ),
      payment_address: payment_address,
      droplocations: droplocations,
    );
    // distance: distance.rows[0].elements[0].distance.value);
  }

  Map<String, dynamic> toJson() {
    return {
      "pickup": pickup,
      "drop": drop,
      "id": id,
      "delivery_type": delivery_type,
      "parcel_weight": parcel_weight,
      "phone_number": phone_number,
      "notify_sms": notify_sms,
      "courier_bag": courier_bag,
      "vehicle": vehicle,
      "status": status,
      "payment_method": payment_method,
      "customer": customer,
      "package": package,
      "time_stamp": time_stamp,
      "parcel_value": parcel_value,
      "amount": amount,
      "distance": distance,
      "orderStatus": orderStatus,
      "rider": rider
    };
  }
}
