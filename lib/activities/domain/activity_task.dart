class ActivityTask {
  final String id;
  final String name;
  final String assignedToEmail;
  final String status;
  final String comments;
  final String files;
  final String links;

  ActivityTask({
    this.id = '',
    required this.name,
    this.assignedToEmail = '',
    this.status = 'Pendiente',
    this.comments = '',
    this.files = '',
    this.links = '',
  });

  ActivityTask copyWith({
    String? id,
    String? name,
    String? assignedToEmail,
    String? status,
    String? comments,
    String? files,
    String? links,
  }) {
    return ActivityTask(
      id: id ?? this.id,
      name: name ?? this.name,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      files: files ?? this.files,
      links: links ?? this.links,
    );
  }

  // API sends files/links as List<String>; UI uses them as single String (newline-joined)
  static String _listToString(dynamic value) {
    if (value is List) return value.join('\n');
    return value?.toString() ?? '';
  }

  static List<String> _stringToList(String value) {
    if (value.trim().isEmpty) return [];
    return value.split('\n').where((s) => s.trim().isNotEmpty).toList();
  }

  Map<String, dynamic> toApiMap() => {
    'status': status,
    'comments': comments,
    'files': _stringToList(files),
    'links': _stringToList(links),
  };

  factory ActivityTask.fromMap(Map<String, dynamic> map) => ActivityTask(
    id: map['id']?.toString() ?? '',
    name: map['name'] ?? '',
    assignedToEmail: map['assignedToEmail'] ?? '',
    status: map['status'] ?? 'Pendiente',
    comments: map['comments'] ?? '',
    files: _listToString(map['files']),
    links: _listToString(map['links']),
  );
}
