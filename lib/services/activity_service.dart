import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignum/models/activity.dart';
import 'package:path_provider/path_provider.dart';

// BANDERA PARA ACTIVAR O DESACTIVAR EL MODO LOCAL
const bool USE_LOCAL_JSON = true; // CAMBIAR A FALSE PARA VOLVER A FIREBASE

class ActivityService {
  final _col = FirebaseFirestore.instance.collection('activities');
  
  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/db.json');
  }

  Future<List<Activity>> _readLocal() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return [];
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((e) => Activity.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _writeLocal(List<Activity> activities) async {
    final file = await _localFile;
    final String contents = jsonEncode(activities.map((a) => a.toMap()).toList());
    await file.writeAsString(contents);
  }

  Future<List<Activity>> getActivities() async {
    if (USE_LOCAL_JSON) {
      return await _readLocal();
    } else {
      final snap = await _col.get();
      return snap.docs.map((d) => Activity.fromMap(d.data())).toList();
    }
  }

  Future<void> createActivity(Activity a) async {
    if (USE_LOCAL_JSON) {
      final list = await _readLocal();
      list.add(a);
      await _writeLocal(list);
    } else {
      await _col.doc(a.id).set(a.toMap());
    }
  }

  Future<void> updateInvitedEmails(String activityId, List<String> emails) async {
    if (USE_LOCAL_JSON) {
      final list = await _readLocal();
      final idx = list.indexWhere((a) => a.id == activityId);
      if (idx != -1) {
        final existingActivity = list[idx];
        final currentEmails = existingActivity.invitedEmails;
        for (var email in emails) {
          if (!currentEmails.contains(email)) currentEmails.add(email);
        }
        await _writeLocal(list);
      }
    } else {
      await _col.doc(activityId).update({
        'invitedEmails': FieldValue.arrayUnion(emails)
      });
    }
  }
}
