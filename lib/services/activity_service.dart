import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignum/models/activity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignum/auth.dart';
import 'package:assignum/services/user_service.dart';

// BANDERA PARA ACTIVAR O DESACTIVAR EL MODO LOCAL
const bool USE_LOCAL_JSON = false; // CAMBIAR A FALSE PARA VOLVER A FIREBASE

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
      print('DEBUG ERROR PARSEO DB JSON: $e');
      return [];
    }
  }

  Future<void> wipeLocalDb() async {
    if (USE_LOCAL_JSON) {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _writeLocal(List<Activity> activities) async {
    final file = await _localFile;
    final String contents = jsonEncode(activities.map((a) => a.toMap()).toList());
    await file.writeAsString(contents);
  }

  Future<List<Activity>> getActivities() async {
    final User? user = Auth().currentUser;
    if (user == null) return [];

    if (USE_LOCAL_JSON) {
      final all = await _readLocal();
      return all.where((a) {
        bool isCreator = a.uid == user.uid;
        bool isInvited = user.email != null && a.invitedEmails.contains(user.email);
        return isCreator || isInvited;
      }).toList();
    } else {
      final q1 = await _col.where('uid', isEqualTo: user.uid).get();
      // It's possible email is null if not authenticated via email, but assuming normal flow here:
      final q2 = user.email != null ? await _col.where('acceptedEmails', arrayContains: user.email!).get() : null;

      final Map<String, Activity> uniqueActs = {};
      for (var doc in q1.docs) {
        uniqueActs[doc.id] = Activity.fromMap(doc.data());
      }
      if (q2 != null) {
        for (var doc in q2.docs) {
           uniqueActs[doc.id] = Activity.fromMap(doc.data());
        }
      }
      return uniqueActs.values.toList();
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

  Future<List<Activity>> getPendingInvitations() async {
    final User? user = Auth().currentUser;
    if (user == null || user.email == null || USE_LOCAL_JSON) return [];
    final q = await _col.where('invitedEmails', arrayContains: user.email!).get();
    return q.docs.map((d) => Activity.fromMap(d.data())).toList();
  }

  Future<void> acceptInvitation(String activityId) async {
    final user = Auth().currentUser;
    if (user == null || user.email == null || USE_LOCAL_JSON) return;
    
    // Conseguir nombre real
    final profile = await UserService().getProfile(user.uid);
    final name = profile?.fullName ?? user.displayName ?? user.email!;

    await _col.doc(activityId).update({
      'invitedEmails': FieldValue.arrayRemove([user.email]),
      'acceptedEmails': FieldValue.arrayUnion([user.email]),
      'memberNames.${user.email!.replaceAll('.', '_')}': name, // Firebase won't accept periods in keys easily, replaced with _
    });
  }

  Future<void> declineInvitation(String activityId) async {
    final user = Auth().currentUser;
    if (user == null || user.email == null || USE_LOCAL_JSON) return;
    await _col.doc(activityId).update({
      'invitedEmails': FieldValue.arrayRemove([user.email])
    });
  }

  Future<void> deleteActivity(String id) async {
    if (USE_LOCAL_JSON) {
      final list = await _readLocal();
      list.removeWhere((a) => a.id == id);
      await _writeLocal(list);
    } else {
      await _col.doc(id).delete();
    }
  }
}
