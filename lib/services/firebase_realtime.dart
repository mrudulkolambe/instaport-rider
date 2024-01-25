import 'package:firebase_database/firebase_database.dart';

// Initialize the Realtime Database

class RealtimeService {
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  Future<String> _createEntry() async {
    await ref.set({
      "id": "John",
      "age": 18,
      "address": {"line1": "100 Mountain View"}
    });
    return "true";
  }
}
