import 'package:instaport_rider/models/rider_model.dart';
import 'package:instaport_rider/models/order_model.dart';

class RiderTransactions {
  bool error;
  String message;
  List<SingleTransaction> transactions;

  RiderTransactions({
    required this.error,
    required this.message,
    required this.transactions,
  });

  factory RiderTransactions.fromJson(dynamic json) {
    final error = json['error'] as bool;
    final message = json['message'] as String;
    final transactions = List.from(json["transactions"]).map((e) {
      return SingleTransaction.fromJson(e);
    }).toList();
    return RiderTransactions(
      error: error,
      message: message,
      transactions: transactions,
    );
  }
}

class SingleTransaction {
  String id;
  double amount;
  int timestamp;
  String message;
  Rider rider;
  String transactionId;
  bool completed;
  bool request;
  bool debit;
  Orders? order;

  SingleTransaction({
    required this.id,
    required this.amount,
    required this.timestamp,
    required this.message,
    required this.rider,
    required this.transactionId,
    required this.completed,
    required this.request,
    required this.debit,
    this.order,
  });

  factory SingleTransaction.fromJson(dynamic json) {
    final id = json['_id'] as String;
    final amount = json['amount'] + 0.0 as double;
    final timestamp = json['timestamp'] as int;
    final message = json['message'] as String;
    final rider = Rider.fromJson(json['rider']);
    final transactionId = json['transactionID'] as String;
    final completed = json['completed'] as bool;
    final request = json['request'] as bool;
    final debit = json['debit'] as bool;
    final order = json["order"] == null ? null : Orders.fromJson(json["order"]);
    
    return SingleTransaction(
      id: id,
      amount: amount,
      timestamp: timestamp,
      message: message,
      rider: rider,
      transactionId: transactionId,
      completed: completed,
      request: request,
      debit: debit,
      order: order,
    );
  }
}
