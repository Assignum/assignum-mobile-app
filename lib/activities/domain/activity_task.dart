class ActivityTask {
  final String name;
  final String assignedToEmail;
  final String status;
  final String comments;
  final String files;
  final String links;

  ActivityTask({
    required this.name,
    this.assignedToEmail = '',
    this.status = 'Pendiente',
    this.comments = '',
    this.files = '',
    this.links = '',
  });

  ActivityTask copyWith({
    String? name,
    String? assignedToEmail,
    String? status,
    String? comments,
    String? files,
    String? links,
  }) {
    return ActivityTask(
      name: name ?? this.name,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      files: files ?? this.files,
      links: links ?? this.links,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'assignedToEmail': assignedToEmail,
    'status': status,
    'comments': comments,
    'files': files,
    'links': links,
  };

  factory ActivityTask.fromMap(Map<String, dynamic> map) => ActivityTask(
    name: map['name'] ?? '',
    assignedToEmail: map['assignedToEmail'] ?? '',
    status: map['status'] ?? 'Pendiente',
    comments: map['comments'] ?? '',
    files: map['files'] ?? '',
    links: map['links'] ?? '',
  );
}
