import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignum/models/activity.dart';

class ActivityService {
  final _col = FirebaseFirestore.instance.collection('activities');

  Future<void> createActivity(Activity a) async {
    await _col.doc(a.id).set(a.toMap());
  }

  Future<void> updateInvitedEmails(String activityId, List<String> emails) async {
    await _col.doc(activityId).update({
      'invitedEmails': FieldValue.arrayUnion(emails)
    });
  }
}
