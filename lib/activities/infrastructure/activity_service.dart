import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/domain/inbox_item.dart';

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
        ))
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  /// Stream en tiempo real del número de invitaciones pendientes (sin aceptar).
  Stream<int> getPendingInvitationsCountStream() {
    final email = AuthSession().email ?? '';
    if (email.isEmpty) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('activities')
        .where('invitedEmails', arrayContains: email)
        .snapshots()
        .map((snap) => snap.docs.where((doc) {
              final accepted =
                  List<String>.from(doc.data()['acceptedEmails'] ?? []);
              return !accepted.contains(email);
            }).length);
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

  // ── Activities REST ──────────────────────────────────────────────────────────

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
    // Crear la actividad
    final data = await ApiClient.post('/api/activities', {
      'name': name,
      'dueDate': dueDate.toIso8601String().split('T')[0],
      if (documentLink.isNotEmpty) 'documentLink': documentLink,
    }) as Map<String, dynamic>;
    final activity = Activity.fromMap(data);

    // Enviar tareas al endpoint dedicado si las hay
    if (tasks.isNotEmpty) {
      await ApiClient.post('/api/activities/${activity.id}/tasks', {
        'tasks': tasks.map((t) => t.toCreationMap()).toList(),
      });
    }

    return activity;
  }

  /// Edita nombre, fecha límite o enlace (solo líder). Cambiar la fecha avisa a los miembros.
  Future<void> updateActivity(
    String id, {
    String? name,
    DateTime? dueDate,
    String? documentLink,
  }) async {
    await ApiClient.put('/api/activities/$id', {
      if (name != null) 'name': name,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String().split('T')[0],
      if (documentLink != null) 'documentLink': documentLink.isEmpty ? null : documentLink,
    });
  }

  /// Un miembro sale de la actividad; sus tareas sin terminar quedan sin asignar.
  Future<void> leaveActivity(String id) async {
    await ApiClient.post('/api/activities/$id/leave');
  }

  /// El líder cede el liderazgo a un miembro aceptado y pasa a ser miembro.
  Future<void> transferLeadership(String id, String newLeaderEmail) async {
    await ApiClient.post('/api/activities/$id/leader', {'email': newLeaderEmail});
  }

  Future<void> deleteActivity(String id) async {
    await ApiClient.delete('/api/activities/$id');
  }

  Future<void> finalizeActivity(String id) async {
    await ApiClient.post('/api/activities/$id/finalize');
  }

  // ── Tasks REST ──────────────────────────────────────────────────────────────
  // Todas las escrituras de tareas pasan por el backend: valida permisos y guarda en una
  // transacción, así dos miembros que actualizan a la vez no se pisan. Los errores se
  // propagan para que la pantalla los muestre; la UI se actualiza sola por el stream.

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

  /// Corrige la definición de una tarea (nombre, tipo, complejidad, prioridad, horas).
  Future<void> editTask(String activityId, String taskId, ActivityTask task) async {
    await ApiClient.patch('/api/activities/$activityId/tasks/$taskId', task.toCreationMap());
  }

  Future<void> deleteTask(String activityId, String taskId) async {
    await ApiClient.delete('/api/activities/$activityId/tasks/$taskId');
  }

  Future<void> verifyTask(String activityId, String taskId) async {
    await ApiClient.post('/api/activities/$activityId/tasks/$taskId/verify');
  }

  /// Reparto inicial de tareas ("Dividir tareas").
  Future<void> assignTasks(String activityId) async {
    await ApiClient.post('/api/activities/$activityId/tasks/assign');
  }

  Future<List<ActivityTask>> addTasks(String activityId, List<ActivityTask> tasks) async {
    final list = await ApiClient.post('/api/activities/$activityId/tasks', {
      'tasks': tasks.map((t) => t.toCreationMap()).toList(),
    }) as List<dynamic>;
    return list.map((e) => ActivityTask.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Propuesta (sin guardar) de cómo repartir [taskIds] entre [memberEmails],
  /// considerando la carga previa de cada uno. Devuelve taskId → email y si se
  /// calculó sin el servicio ML ([usedFallback]).
  Future<({Map<String, String> assignments, bool usedFallback})> previewRedistribution(
    String activityId, {
    required List<String> taskIds,
    required List<String> memberEmails,
  }) async {
    final data = await ApiClient.post(
      '/api/activities/$activityId/tasks/redistribute/preview',
      {'taskIds': taskIds, 'memberEmails': memberEmails},
    ) as Map<String, dynamic>;
    return (
      assignments: {
        for (final a in data['assignments'] as List<dynamic>)
          (a as Map)['taskId'] as String: a['assignedToEmail'] as String,
      },
      usedFallback: data['assignmentMode'] == 'fallback',
    );
  }

  /// Asigna tareas a estudiantes concretos (taskId → email, o null para dejarla sin asignar).
  /// [assignmentMode] indica de dónde salió el reparto: 'ml' o 'fallback' si es la
  /// propuesta de [previewRedistribution]; por defecto es un cambio manual.
  Future<void> applyAssignments(String activityId, Map<String, String?> assignments,
      {String assignmentMode = 'manual'}) async {
    await ApiClient.put('/api/activities/$activityId/tasks/assignments', {
      'assignments': assignments.entries
          .map((e) => {'taskId': e.key, 'assignedToEmail': e.value})
          .toList(),
      'assignmentMode': assignmentMode,
    });
  }

  // ── Members & Invitations ────────────────────────────────────────────────────

  /// Invita a cada correo de forma independiente para que un correo inválido no
  /// bloquee al resto. Devuelve los correos que fallaron con su motivo.
  Future<Map<String, String>> inviteMembers(String activityId, List<String> emails) async {
    final failures = <String, String>{};
    for (final email in emails) {
      try {
        await ApiClient.post('/api/activities/$activityId/invitations', {'email': email});
      } on ApiException catch (e) {
        failures[email] = _inviteErrorMessage(e);
      } catch (_) {
        failures[email] = 'Error de conexión';
      }
    }
    return failures;
  }

  static String _inviteErrorMessage(ApiException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('does not exist')) return 'No tiene cuenta en Assignum';
    if (msg.contains('already invited')) return 'Ya está en el grupo o invitado';
    if (msg.contains('yourself')) return 'No puedes invitarte a ti mismo';
    if (msg.contains('finalized')) return 'La actividad ya fue finalizada';
    return e.message;
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final list = await ApiClient.get('/api/notifications') as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Quita a un miembro. Devuelve los ids de sus tareas que quedaron sin asignar.
  Future<List<String>> removeMember(String activityId, String email) async {
    final data = await ApiClient.delete(
        '/api/activities/$activityId/members/${Uri.encodeComponent(email)}') as Map<String, dynamic>;
    return List<String>.from(data['unassignedTaskIds'] ?? []);
  }

  /// Cancela una invitación pendiente. Devuelve los ids de las tareas que quedaron sin asignar.
  Future<List<String>> cancelInvitation(String activityId, String email) async {
    final data = await ApiClient.delete(
        '/api/activities/$activityId/invitations/${Uri.encodeComponent(email)}') as Map<String, dynamic>;
    return List<String>.from(data['unassignedTaskIds'] ?? []);
  }

  Future<void> resendInvitation(String activityId, String email) async {
    await ApiClient.post(
        '/api/activities/$activityId/invitations/${Uri.encodeComponent(email)}/resend');
  }

  Future<void> acceptInvitation(String activityId) async {
    await ApiClient.post('/api/activities/$activityId/invitations/accept');
  }

  Future<void> declineInvitation(String activityId) async {
    await ApiClient.post('/api/activities/$activityId/invitations/decline');
  }

  // ── Bandeja de avisos ───────────────────────────────────────────────────────

  Future<List<InboxItem>> getInbox() async {
    final list = await ApiClient.get('/api/notifications/inbox') as List<dynamic>;
    return list.map((e) => InboxItem.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadInboxCount() async {
    final items = await getInbox();
    return items.where((i) => !i.read).length;
  }

  Future<void> markInboxRead() async {
    await ApiClient.post('/api/notifications/inbox/read');
  }

  // ── File upload (Cloudinary) ──────────────────────────────────────────────────

  // ⚠️  Reemplaza estos dos valores con los de tu cuenta Cloudinary:
  static const _cloudinaryCloud  = 'dgcymtdbq';
  static const _cloudinaryPreset = 'assignum_uploads';

  /// Sube un archivo a Cloudinary y devuelve la URL segura de descarga.
  /// Usa un upload preset sin firma (unsigned), sin necesidad de backend.
  Future<String> uploadTaskFile(
    String activityId,
    String taskId,
    File file,
    String filename,
  ) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloud/auto/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryPreset
      ..fields['folder'] = 'activities/$activityId/tasks/$taskId'
      ..files.add(await http.MultipartFile.fromPath('file', file.path,
          filename: filename));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary error ${streamed.statusCode}: $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  // ── File helpers ──────────────────────────────────────────────────────────────

  static bool isImageUrl(String url) {
    // Cloudinary pone PDFs y docs también bajo /image/upload/ cuando resource_type=auto,
    // por eso no podemos fiarnos del path — usamos la extensión del archivo.
    final ext = url.toLowerCase().split('?').first.split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  static String filenameFromUrl(String url) {
    try {
      // Cloudinary: https://res.cloudinary.com/.../filename.ext
      final path = Uri.parse(url).path;
      return path.split('/').last.split('?').first;
    } catch (_) {
      return 'Archivo';
    }
  }
}
