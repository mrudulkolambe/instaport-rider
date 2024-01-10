class SignInResponse {
  bool error;
  String message;
  String token;

  SignInResponse({
    required this.error,
    required this.message,
    required this.token,
  });

  factory SignInResponse.fromJson(dynamic json) {
    final error = json['error'] as bool;
    final message = json['message'] as String;
    final token = json['token'] as String;
    return SignInResponse(
      error: error,
      message: message,
      token: token,
    );
  }
}

class User {
  String fullname;
  String mobileno;
  String usecase;
  bool verified;
  String role;

  User({
    required this.fullname,
    required this.mobileno,
    required this.usecase,
    required this.verified,
    required this.role,
  });

  factory User.fromJson(dynamic json) {
    final fullname = json['fullname'] as String;
    final mobileno = json['mobileno'] as String;
    final usecase = json['usecase'] as String;
    final verified = json['verified'] as bool;
    final role = json['role'] as String;
    return User(
      fullname: fullname,
      mobileno: mobileno,
      usecase: usecase,
      verified: verified,
      role: role,
    );
  }
}
