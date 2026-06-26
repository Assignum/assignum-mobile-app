class UserProfile {
  final String uid;
  final String fullName;
  final DateTime? birthDate;

  // Competencias Técnicas (1–5)
  final int backendSkill;
  final int frontendSkill;
  final int databaseSkill;
  final int testingSkill;
  final int documentationSkill;
  final int gitGithubSkill;
  final int agileMethodologiesSkill;

  // Competencias Colaborativas (1–5)
  final int teamworkSkill;
  final int communicationSkill;
  final int leadershipSkill;
  final int organizationSkill;

  // Experiencia y Disponibilidad
  final int projectsCompleted;
  final int availableHoursPerWeek;
  final String lastRole;
  final int lastRolePerformance;
  final int peerEvaluation;

  UserProfile({
    required this.uid,
    required this.fullName,
    this.birthDate,
    this.backendSkill = 3,
    this.frontendSkill = 3,
    this.databaseSkill = 3,
    this.testingSkill = 3,
    this.documentationSkill = 3,
    this.gitGithubSkill = 3,
    this.agileMethodologiesSkill = 3,
    this.teamworkSkill = 3,
    this.communicationSkill = 3,
    this.leadershipSkill = 3,
    this.organizationSkill = 3,
    this.projectsCompleted = 0,
    this.availableHoursPerWeek = 10,
    this.lastRole = 'Frontend',
    this.lastRolePerformance = 3,
    this.peerEvaluation = 3,
  });

  Map<String, dynamic> toApiMap() => {
    'fullName': fullName,
    if (birthDate != null)
      'birthDate': birthDate!.toIso8601String().split('T')[0],
    'backendSkill': backendSkill,
    'frontendSkill': frontendSkill,
    'databaseSkill': databaseSkill,
    'testingSkill': testingSkill,
    'documentationSkill': documentationSkill,
    'gitGithubSkill': gitGithubSkill,
    'agileMethodologiesSkill': agileMethodologiesSkill,
    'teamworkSkill': teamworkSkill,
    'communicationSkill': communicationSkill,
    'leadershipSkill': leadershipSkill,
    'organizationSkill': organizationSkill,
    'projectsCompleted': projectsCompleted,
    'availableHoursPerWeek': availableHoursPerWeek,
    'lastRole': lastRole,
    'lastRolePerformance': lastRolePerformance,
    'peerEvaluation': peerEvaluation,
  };

  static UserProfile fromMap(Map<String, dynamic> m) => UserProfile(
    uid: m['uid'] as String? ?? '',
    fullName: m['fullName'] as String? ?? '',
    birthDate: m['birthDate'] != null
        ? DateTime.tryParse(m['birthDate'].toString())
        : null,
    backendSkill:              _int(m, 'backendSkill'),
    frontendSkill:             _int(m, 'frontendSkill'),
    databaseSkill:             _int(m, 'databaseSkill'),
    testingSkill:              _int(m, 'testingSkill'),
    documentationSkill:        _int(m, 'documentationSkill'),
    gitGithubSkill:            _int(m, 'gitGithubSkill'),
    agileMethodologiesSkill:   _int(m, 'agileMethodologiesSkill'),
    teamworkSkill:             _int(m, 'teamworkSkill'),
    communicationSkill:        _int(m, 'communicationSkill'),
    leadershipSkill:           _int(m, 'leadershipSkill'),
    organizationSkill:         _int(m, 'organizationSkill'),
    projectsCompleted:         _int(m, 'projectsCompleted', def: 0),
    availableHoursPerWeek:     _int(m, 'availableHoursPerWeek', def: 10),
    lastRole:    m['lastRole'] as String? ?? 'Frontend',
    lastRolePerformance: _int(m, 'lastRolePerformance'),
    peerEvaluation:      _int(m, 'peerEvaluation'),
  );

  static int _int(Map<String, dynamic> m, String key, {int def = 3}) =>
      (m[key] as num?)?.toInt() ?? def;
}
