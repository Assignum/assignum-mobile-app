import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignum/models/user_profile.dart';

class UserService {
  final _col = FirebaseFirestore.instance.collection('users');

  Future<void> createOrUpdateProfile(UserProfile p) async {
    await _col.doc(p.uid).set(p.toMap(), SetOptions(merge: true));
  }

  Future<bool> profileExists(String uid) async {
    final doc = await _col.doc(uid).get();
    return doc.exists;
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }
}
