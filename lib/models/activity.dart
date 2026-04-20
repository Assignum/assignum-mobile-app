import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String uid;
  final String name;
  final DateTime dueDate;
  final String documentLink;
  final List<String> tasks;

  Activity({
    required this.id,
    required this.uid,
    required this.name,
    required this.dueDate,
    required this.documentLink,
    required this.tasks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'dueDate': dueDate.toIso8601String(),
      'documentLink': documentLink,
      'tasks': tasks,
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
    );
  }
}
