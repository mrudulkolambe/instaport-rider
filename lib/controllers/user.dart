import 'package:get/state_manager.dart';
import 'package:instaport_rider/models/rider_model.dart';

class RiderController extends GetxController {
  Rider rider = Rider(
    id: "",
    fullname: "",
    mobileno: "",
    role: "customer",
    wallet_amount: 0.0,
    age: "",
    image: ""
  );

  void updateRider(Rider data) {
    rider = data;
    update();
  }
}