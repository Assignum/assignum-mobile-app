import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String uid;
  final String name;
  final DateTime dueDate;
  final String documentLink;
  final List<String> tasks;
  final List<String> invitedEmails;
  final List<String> acceptedEmails;
  final Map<String, String> memberNames;

  Activity({
    required this.id,
    required this.uid,
    required this.name,
    required this.dueDate,
    required this.documentLink,
    required this.tasks,
    this.invitedEmails = const [],
    this.acceptedEmails = const [],
    this.memberNames = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'dueDate': dueDate.toIso8601String(),
      'documentLink': documentLink,
      'tasks': tasks,
      'invitedEmails': invitedEmails,
      'acceptedEmails': acceptedEmails,
      'memberNames': memberNames,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      documentLink: map['documentLink'] ?? '',
      tasks: List<String>.from(map['tasks'] ?? []),
      invitedEmails: List<String>.from(map['invitedEmails'] ?? []),
      acceptedEmails: List<String>.from(map['acceptedEmails'] ?? []),
      memberNames: Map<String, String>.from(map['memberNames'] ?? {}),
    );
  }
}
