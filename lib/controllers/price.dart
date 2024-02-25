import 'package:get/state_manager.dart';
import 'package:instaport_rider/models/price_model.dart';

class PriceController extends GetxController {
  PriceManipulation priceManipulation = PriceManipulation(
    id: "",
    perKilometerCharge: 0,
    additionalPerKilometerCharge: 0,
    additionalPickupCharge: 0,
    securityFeesCharges: 0,
    baseOrderCharges: 0,
    instaportCommission: 0,
    additionalDropCharge: 0,
    cancellationCharges: 0,
    withdrawalCharges: 0,
  );

  void updatePrice(PriceManipulation data) {
    priceManipulation = data;
    update();
  }
}
