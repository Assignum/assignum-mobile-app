import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';

class ActivityService {
  static Activity _fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    data['id'] = doc.id;
    return Activity.fromMap(data);
  }

  // ── Firestore real-time streams ──────────────────────────────────────────────

  Stream<List<Activity>> getActivitiesStream() {
    final uid   = AuthSession().uid   ?? '';
    final email = AuthSession().email ?? '';
    return FirebaseFirestore.instance
        .collection('activities')
        .where(Filter.or(
          Filter('uid', isEqualTo: uid),
          Filter('acceptedEmails', arrayContains: email),
          Filter('invitedEmails',  arrayContains: email),
        ))
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  Stream<Activity?> getActivityStreamById(String activityId) {
    return FirebaseFirestore.instance
        .collection('activities')
        .doc(activityId)
        .snapshots()
        .map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  // ── Firestore direct reads ───────────────────────────────────────────────────

  Future<Activity?> getActivityFromFirestore(String id) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('activities').doc(id).get();
      return doc.exists ? _fromDoc(doc) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Firestore direct writes (instant, bypasses slow backend) ─────────────────

  /// Updates task fields directly in Firestore. Fast and real-time for all devices.
  /// Also fires a background REST call to keep backend stats in sync.
  Future<void> updateTaskDirectly(
    String activityId,
    String taskId, {
    required String status,
    required String comments,
    required String files,
    required String links,
  }) async {
    final filesList = files.trim().isEmpty
        ? <String>[]
        : files.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final linksList = links.trim().isEmpty
        ? <String>[]
        : links.split('\n').where((s) => s.trim().isNotEmpty).toList();

    final actRef = FirebaseFirestore.instance.collection('activities').doc(activityId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(actRef);
      if (!snap.exists) return;
      final tasks = List<dynamic>.from(
          (snap.data() as Map<String, dynamic>)['tasks'] ?? []);
      final idx = tasks.indexWhere(
          (t) => (t as Map)['id']?.toString() == taskId);
      if (idx == -1) return;
      final task = Map<String, dynamic>.from(tasks[idx] as Map);
      task['status']   = status;
      task['comments'] = comments;
      task['files']    = filesList;
      task['links']    = linksList;
      tasks[idx] = task;
      tx.update(actRef, {'tasks': tasks});
    });

    // Keep backend DB in sync in background (for dashboard stats)
    ApiClient.put('/api/activities/$activityId/tasks/$taskId', {
      'status': status,
      'comments': comments,
      'files': filesList,
      'links': linksList,
    }).catchError((_) {});
  }

  /// Sets task status to Verificado directly in Firestore.
  Future<void> verifyTaskDirectly(String activityId, String taskId) async {
    final actRef = FirebaseFirestore.instance.collection('activities').doc(activityId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(actRef);
      if (!snap.exists) return;
      final tasks = List<dynamic>.from(
          (snap.data() as Map<String, dynamic>)['tasks'] ?? []);
      final idx = tasks.indexWhere(
          (t) => (t as Map)['id']?.toString() == taskId);
      if (idx == -1) return;
      final task = Map<String, dynamic>.from(tasks[idx] as Map);
      task['status'] = 'Verificado';
      tasks[idx] = task;
      tx.update(actRef, {'tasks': tasks});
    });

    // Keep backend in sync in background
    ApiClient.post('/api/activities/$activityId/tasks/$taskId/verify')
        .catchError((_) {});
  }

  // ── Activities REST ──────────────────────────────────────────────────────────

  Future<List<Activity>> getActivities() async {
    final list = await ApiClient.get('/api/activities') as List<dynamic>;
    return list.map((e) => Activity.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, String>> getActivityMembers(String activityId) async {
    try {
      final data = await ApiClient.get('/api/activities/$activityId/members') as Map<String, dynamic>;
      final members = data['members'] as List<dynamic>? ?? [];
      return {
        for (final m in members)
          if (m['uid'] != null && m['name'] != null)
            m['uid'] as String: m['name'] as String,
      };
    } catch (_) {
      return {};
    }
  }

  Future<Activity?> getActivity(String id) async {
    try {
      final data = await ApiClient.get('/api/activities/$id') as Map<String, dynamic>;
      return Activity.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  Future<Activity> createActivity({
    required String name,
    required DateTime dueDate,
    String documentLink = '',
    List<ActivityTask> tasks = const [],
  }) async {
    final data = await ApiClient.post('/api/activities', {
      'name': name,
      'dueDate': dueDate.toIso8601String().split('T')[0],
      if (documentLink.isNotEmpty) 'documentLink': documentLink,
      if (tasks.isNotEmpty) 'tasks': tasks.map((t) => {'name': t.name}).toList(),
    }) as Map<String, dynamic>;
    return Activity.fromMap(data);
  }

  Future<void> deleteActivity(String id) async {
    await ApiClient.delete('/api/activities/$id');
  }

  Future<void> finalizeActivity(String id) async {
    await ApiClient.post('/api/activities/$id/finalize');
  }

  // ── Tasks REST (kept for non-direct operations) ──────────────────────────────

  Future<void> updateTask(
    String activityId,
    String taskId, {
    String? status,
    String? comments,
    String? files,
    String? links,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (comments != null) body['comments'] = comments;
    if (files != null) {
      body['files'] = files.trim().isEmpty
          ? []
          : files.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    if (links != null) {
      body['links'] = links.trim().isEmpty
          ? []
          : links.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    await ApiClient.put('/api/activities/$activityId/tasks/$taskId', body);
  }

  Future<void> verifyTask(String activityId, String taskId) async {
    await ApiClient.post('/api/activities/$activityId/tasks/$taskId/verify');
  }

  Future<void> assignTasks(String activityId) async {
    await ApiClient.post('/api/activities/$activityId/tasks/assign');
  }

  // ── Members & Invitations ────────────────────────────────────────────────────

  Future<void> inviteMembers(String activityId, List<String> emails) async {
    for (final email in emails) {
      await ApiClient.post('/api/activities/$activityId/invitations', {'email': email});
    }
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final list = await ApiClient.get('/api/notifications') as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> acceptInvitation(String activityId) async {
    await ApiClient.post('/api/activities/$activityId/invitations/accept');
  }

  Future<void> declineInvitation(String activityId) async {
    await ApiClient.post('/api/activities/$activityId/invitations/decline');
  }

  // ── Dashboard ────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    final data = await ApiClient.get('/api/dashboard/stats') as Map<String, dynamic>;
    return {
      'totalActivities': (data['totalActivities'] as num?)?.toInt() ?? 0,
      'pendingTasks': (data['pendingTasks'] as num?)?.toInt() ?? 0,
      'upcomingActivities': (data['upcomingActivities'] as num?)?.toInt() ?? 0,
    };
  }
}
