class ActivityTask {
  final String id;
  final String name;
  final String assignedToEmail;
  final String status;
  final String comments;
  final String files;
  final String links;

  // Nuevos campos de creación
  final String taskType;
  final String taskComplexity;
  final String priority;
  final int estimatedHours;

  ActivityTask({
    this.id = '',
    required this.name,
    this.assignedToEmail = '',
    this.status = 'Pendiente',
    this.comments = '',
    this.files = '',
    this.links = '',
    this.taskType = 'Backend',
    this.taskComplexity = 'Medium',
    this.priority = 'Medium',
    this.estimatedHours = 5,
  });

  ActivityTask copyWith({
    String? id,
    String? name,
    String? assignedToEmail,
    String? status,
    String? comments,
    String? files,
    String? links,
    String? taskType,
    String? taskComplexity,
    String? priority,
    int? estimatedHours,
  }) {
    return ActivityTask(
      id: id ?? this.id,
      name: name ?? this.name,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      files: files ?? this.files,
      links: links ?? this.links,
      taskType: taskType ?? this.taskType,
      taskComplexity: taskComplexity ?? this.taskComplexity,
      priority: priority ?? this.priority,
      estimatedHours: estimatedHours ?? this.estimatedHours,
    );
  }

  static String _listToString(dynamic value) {
    if (value is List) return value.join('\n');
    return value?.toString() ?? '';
  }

  static List<String> _stringToList(String value) {
    if (value.trim().isEmpty) return [];
    return value.split('\n').where((s) => s.trim().isNotEmpty).toList();
  }

  // Para actualizar estado/comentarios/archivos de una tarea existente
  Map<String, dynamic> toApiMap() => {
    'status': status,
    'comments': comments,
    'files': _stringToList(files),
    'links': _stringToList(links),
  };

  // Para crear una nueva tarea (incluye todos los campos de definición)
  Map<String, dynamic> toCreationMap() => {
    'name': name,
    'taskType': taskType,
    'taskComplexity': taskComplexity,
    'priority': priority,
    'estimatedHours': estimatedHours,
  };

  factory ActivityTask.fromMap(Map<String, dynamic> map) => ActivityTask(
    id: map['id']?.toString() ?? '',
    name: map['name'] ?? '',
    assignedToEmail: map['assignedToEmail'] ?? '',
    status: map['status'] ?? 'Pendiente',
    comments: map['comments'] ?? '',
    files: _listToString(map['files']),
    links: _listToString(map['links']),
    taskType: map['taskType'] as String? ?? 'Backend',
    taskComplexity: map['taskComplexity'] as String? ?? 'Medium',
    priority: map['priority'] as String? ?? 'Medium',
    estimatedHours: (map['estimatedHours'] as num?)?.toInt() ?? 5,
  );
}
