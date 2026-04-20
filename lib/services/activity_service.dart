import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignum/models/activity.dart';

class ActivityService {
  final _col = FirebaseFirestore.instance.collection('activities');

  Future<void> createActivity(Activity a) async {
    await _col.doc(a.id).set(a.toMap());
  }
}
