/// Aviso guardado en la bandeja (aceptaciones, reasignaciones, recordatorios…).
class InboxItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final String activityId;
  final bool read;
  final DateTime createdAt;

  InboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.activityId,
    required this.read,
    required this.createdAt,
  });

  factory InboxItem.fromMap(Map<String, dynamic> map) => InboxItem(
        id: map['id'] as String? ?? '',
        type: map['type'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        activityId: map['activityId'] as String? ?? '',
        read: map['read'] as bool? ?? false,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
