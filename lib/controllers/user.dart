import 'package:get/state_manager.dart';
import 'package:instaport_rider/models/rider_model.dart';

class RiderController extends GetxController {
  Rider rider = Rider(
    id: "",
    fullname: "",
    applied: false,
    timestamp: 0,
    verified: false,
    mobileno: "",
    token: "",
    role: "customer",
    wallet_amount: 0.0,
    requestedAmount: 0.0,
    age: "",
    image: RiderDocument(status: 'upload', url: "", type: "image"),
    status: "available",
    approve: false,
    aadharcard: RiderDocument(status: 'upload', url: "", type: "aadhar"),
    pancard: RiderDocument(status: 'upload', url: "", type: "pan"),
  );

  void updateRider(Rider data) {
    rider = data;
    update();
  }
}
