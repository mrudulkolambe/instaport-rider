// ignore_for_file: non_constant_identifier_names

class SignInResponse {
  bool error;
  String message;
  String? token;

  SignInResponse({
    required this.error,
    required this.message,
    required this.token,
  });

  factory SignInResponse.fromJson(dynamic json) {
    final error = json['error'] as bool;
    final message = json['message'] as String;
    final token = json['token'] ?? "";
    return SignInResponse(
      error: error,
      message: message,
      token: token,
    );
  }
}

class RiderDocument {
  String url;
  String status;
  String type;
  String? reason;

  RiderDocument({
    required this.status,
    required this.url,
    required this.type,
    this.reason,
  });

  factory RiderDocument.fromJson(dynamic json) {
    final url = json["url"];
    final status = json["status"];
    final type = json["type"];
    final reason = json["reason"] ?? "" as String;
    return RiderDocument(
      status: status,
      url: url,
      type: type,
      reason: reason,
    );
  }
}

class Rider {
  String id;
  String fullname;
  String mobileno;
  String role;
  String age;
  String status;
  String? reason;
  RiderDocument? image;
  String token;
  int timestamp;
  double wallet_amount;
  double requestedAmount;
  bool approve;
  ReferenceContact? referenceContact1;
  ReferenceContact? referenceContact2;
  String? address;
  RiderDocument? aadharcard;
  RiderDocument? pancard;
  RiderDocument? rc_book;
  RiderDocument? drivinglicense;
  String? vehicle;
  String? ifsc;
  String? accno;
  String? accname;
  List<String>? orders;
  bool verified;
  bool? isDue;
  bool applied;

  Rider({
    required this.id,
    required this.fullname,
    required this.timestamp,
    required this.mobileno,
    required this.role,
    required this.age,
    this.image,
    required this.token,
    required this.wallet_amount,
    required this.status,
    required this.approve,
    required this.verified,
    this.reason,
    required this.requestedAmount,
    this.address,
    required this.aadharcard,
    required this.pancard,
    this.vehicle,
    this.ifsc,
    this.accname,
    this.accno,
    this.referenceContact1,
    this.referenceContact2,
    this.drivinglicense,
    this.rc_book,
    required this.applied,
    this.orders,
    this.isDue,
  });

  factory Rider.fromJson(dynamic json) {
    print("APPLIED ${json["applied"]}");
    final id = json['_id'] as String;
    final fullname = json['fullname'] as String;
    final mobileno = json['mobileno'] as String;
    final status = json['status'] as String;
    final token = json['token'] as String;
    final applied = json["applied"] as bool;
    final verified = json["verified"] as bool;
    final approve = json['approve'] as bool;
    final isDue = json['isDue'] as bool;
    final reason = json['reason'] as String;
    final role = json['role'] as String;
    final age = json['age'] as String;
    final image =
        json["image"] == RiderDocument(status: "upload", url: "", type: "image")
            ? null
            : RiderDocument.fromJson(json["image"]);
    final wallet_amount = json["wallet_amount"] + 0.0 as double;
    final requestedAmount = json["requestedAmount"] + 0.0 as double;
    final address = json["address"];
    final aadharcard = json["aadhar_number"] == null
        ? null
        : RiderDocument.fromJson(json["aadhar_number"]);
    final pancard = json["pan_number"] == null
        ? null
        : RiderDocument.fromJson(json["pan_number"]);
    final rcBook = json["rc_book"] == null
        ? null
        : RiderDocument.fromJson(json["rc_book"]);
    final accno = json["acc_no"];
    final timestamp = json["timestamp"];
    final accIFSC = json["acc_ifsc"];
    final accHolder = json["acc_holder"];
    final drivinglicense = json["drivinglicense"] == null
        ? null
        : RiderDocument.fromJson(json["drivinglicense"]);
    final orders = json['orders'] == null
        ? null
        : List.from(json["orders"]).map((e) {
            return e as String;
          }).toList();
    final refCon1 = json["reference_contact_1"] == null
        ? null
        : ReferenceContact.fromJson(json["reference_contact_1"]);
    final refCon2 = json["reference_contact_2"] == null
        ? null
        : ReferenceContact.fromJson(json["reference_contact_2"]);
    return Rider(
      id: id,
      fullname: fullname,
      status: status,
      verified: verified,
      mobileno: mobileno,
      role: role,
      age: age,
      approve: approve,
      reason: reason,
      timestamp: timestamp,
      token: token,
      requestedAmount: requestedAmount,
      image: image,
      wallet_amount: wallet_amount,
      address: address,
      applied: applied,
      aadharcard: aadharcard,
      pancard: pancard,
      accname: accHolder,
      accno: accno,
      ifsc: accIFSC,
      referenceContact1: refCon1,
      referenceContact2: refCon2,
      drivinglicense: drivinglicense,
      orders: orders,
      isDue: isDue,
      rc_book: rcBook,
    );
  }
}

class RiderDataResponse {
  bool error;
  String message;
  Rider rider;

  RiderDataResponse({
    required this.error,
    required this.message,
    required this.rider,
  });

  factory RiderDataResponse.fromJson(dynamic json) {
    final error = json['error'] as bool;
    final message = json['message'] as String;
    final rider = Rider.fromJson(json['rider']);
    return RiderDataResponse(
      error: error,
      message: message,
      rider: rider,
    );
  }
}

class ReferenceContact {
  String name;
  String relation;
  String number;

  ReferenceContact({
    required this.name,
    required this.relation,
    required this.number,
  });

  factory ReferenceContact.fromJson(dynamic json) {
    final name = json['name'] as String;
    final relation = json['relation'] as String;
    final number = json['phonenumber'] as String;
    return ReferenceContact(
      name: name,
      relation: relation,
      number: number,
    );
  }
}
