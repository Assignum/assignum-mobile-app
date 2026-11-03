import 'package:assignum/activities/domain/activity_task.dart';

class Activity {
  final String id;
  final String uid;
  final String leaderName;
  final String name;
  final DateTime dueDate;
  final String documentLink;
  final List<ActivityTask> tasks;
  final List<String> invitedEmails;
  final List<String> acceptedEmails;
  final Map<String, String> memberNames;
  final bool finalized;
  /// 'ml', 'fallback' (reparto sin el servicio ML) o 'manual'; null si nunca se repartió.
  final String? assignmentMode;

  bool get assignedWithoutMl => assignmentMode == 'fallback';

  Activity({
    required this.id,
    required this.uid,
    this.leaderName = '',
    required this.name,
    required this.dueDate,
    required this.documentLink,
    required this.tasks,
    this.invitedEmails = const [],
    this.acceptedEmails = const [],
    this.memberNames = const {},
    this.finalized = false,
    this.assignmentMode,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      leaderName: map['leaderName'] as String? ?? '',
      name: map['name'] ?? '',
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      documentLink: map['documentLink'] ?? '',
      tasks: (map['tasks'] as List<dynamic>?)?.map((e) {
        if (e is String) return ActivityTask(name: e);
        return ActivityTask.fromMap(e as Map<String, dynamic>);
      }).toList() ?? [],
      invitedEmails: List<String>.from(map['invitedEmails'] ?? []),
      acceptedEmails: List<String>.from(map['acceptedEmails'] ?? []),
      memberNames: Map<String, String>.from(map['memberNames'] ?? {}),
      finalized: map['finalized'] ?? false,
      assignmentMode: map['assignmentMode'] as String?,
    );
  }
}
