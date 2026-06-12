import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';

class ActivityService {
  // ── Activities ──────────────────────────────────────────────────────────────

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

  Stream<Activity?> getActivityStream(String id) {
    return Stream.fromFuture(getActivity(id));
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

  // ── Tasks ────────────────────────────────────────────────────────────────────

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
