import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:assignum/activities/domain/auth_facade.dart';

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
    final String? currentUserId = IAuthFacade.instance.currentUserId;
    final String? currentUserEmail = IAuthFacade.instance.currentUserEmail;
    if (currentUserId == null) return [];

    if (USE_LOCAL_JSON) {
      final all = await _readLocal();
      return all.where((a) {
        bool isCreator = a.uid == currentUserId;
        bool isInvited = currentUserEmail != null && a.invitedEmails.contains(currentUserEmail);
        return isCreator || isInvited;
      }).toList();
    } else {
      final q1 = await _col.where('uid', isEqualTo: currentUserId).get();
      // It's possible email is null if not authenticated via email, but assuming normal flow here:
      final q2 = currentUserEmail != null ? await _col.where('acceptedEmails', arrayContains: currentUserEmail).get() : null;

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

  Stream<Activity?> getActivityStream(String id) {
    if (USE_LOCAL_JSON) {
      return Stream.fromFuture(_readLocal()).map((list) {
         final idx = list.indexWhere((a) => a.id == id);
         return idx == -1 ? null : list[idx];
      });
    } else {
      return _col.doc(id).snapshots().map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        return Activity.fromMap(snapshot.data()!);
      });
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

  Future<void> updateActivity(Activity a) async {
    if (USE_LOCAL_JSON) {
      final list = await _readLocal();
      final idx = list.indexWhere((item) => item.id == a.id);
      if (idx != -1) {
        list[idx] = a;
        await _writeLocal(list);
      }
    } else {
      await _col.doc(a.id).update(a.toMap());
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
    final String? currentUserEmail = IAuthFacade.instance.currentUserEmail;
    if (currentUserEmail == null || USE_LOCAL_JSON) return [];
    final q = await _col.where('invitedEmails', arrayContains: currentUserEmail).get();
    return q.docs.map((d) => Activity.fromMap(d.data())).toList();
  }

  Future<void> acceptInvitation(String activityId) async {
    final currentUserId = IAuthFacade.instance.currentUserId;
    final currentUserEmail = IAuthFacade.instance.currentUserEmail;
    final currentUserDisplayName = IAuthFacade.instance.currentUserDisplayName;

    if (currentUserId == null || currentUserEmail == null || USE_LOCAL_JSON) return;
    
    // Conseguir nombre real
    final fullName = await IAuthFacade.instance.getUserName(currentUserId);
    final name = fullName ?? currentUserDisplayName ?? currentUserEmail;

    await _col.doc(activityId).update({
      'invitedEmails': FieldValue.arrayRemove([currentUserEmail]),
      'acceptedEmails': FieldValue.arrayUnion([currentUserEmail]),
      'memberNames.${currentUserEmail.replaceAll('.', '_')}': name, // Firebase won't accept periods in keys easily, replaced with _
    });
  }

  Future<void> declineInvitation(String activityId) async {
    final currentUserEmail = IAuthFacade.instance.currentUserEmail;
    if (currentUserEmail == null || USE_LOCAL_JSON) return;
    await _col.doc(activityId).update({
      'invitedEmails': FieldValue.arrayRemove([currentUserEmail])
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
