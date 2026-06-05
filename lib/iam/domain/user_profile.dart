class UserProfile {
  final String uid;
  final String fullName;
  final DateTime? birthDate;

  final String disponibilidad;
  final String cargaAcademica;
  final int trabajoEnEquipo;
  final int comunicacion;
  final int horasEstudio;

  UserProfile({
    required this.uid,
    required this.fullName,
    this.birthDate,
    required this.disponibilidad,
    required this.cargaAcademica,
    required this.trabajoEnEquipo,
    required this.comunicacion,
    required this.horasEstudio,
  });

  Map<String, dynamic> toApiMap() => {
    'fullName': fullName,
    if (birthDate != null) 'birthDate': birthDate!.toIso8601String().split('T')[0],
    'disponibilidad': disponibilidad,
    'cargaAcademica': cargaAcademica,
    'trabajoEnEquipo': trabajoEnEquipo,
    'comunicacion': comunicacion,
    'horasEstudio': horasEstudio,
  };

  static UserProfile fromMap(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] as String? ?? '',
    fullName: map['fullName'] as String? ?? '',
    birthDate: map['birthDate'] != null
        ? DateTime.tryParse(map['birthDate'].toString())
        : null,
    disponibilidad: map['disponibilidad'] as String? ?? 'Mañana',
    cargaAcademica: map['cargaAcademica'] as String? ?? 'Media',
    trabajoEnEquipo: (map['trabajoEnEquipo'] as num?)?.toInt() ?? 3,
    comunicacion: (map['comunicacion'] as num?)?.toInt() ?? 3,
    horasEstudio: (map['horasEstudio'] as num?)?.toInt() ?? 10,
  );
}
