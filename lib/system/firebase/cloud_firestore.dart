import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFirestoreManager {
  static Map<String, dynamic>? userDataCache;

  static Future<Map<String, dynamic>?> getUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    final data = doc.data();
    userDataCache = data;
    return data;
  }
}
