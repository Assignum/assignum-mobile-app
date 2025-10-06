import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final DateTime? birthDate;

  // Atributos para ML:
  final String disponibilidad;     // Mañana/Tarde/Noche/Fin de semana
  final String cargaAcademica;     // Ligera/Media/Alta
  final int trabajoEnEquipo;       // 1..5
  final int comunicacion;          // 1..5
  final int horasEstudio;          // 0..60

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

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'birthDate':
    birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    'disponibilidad': disponibilidad,
    'cargaAcademica': cargaAcademica,
    'trabajoEnEquipo': trabajoEnEquipo,
    'comunicacion': comunicacion,
    'horasEstudio': horasEstudio,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static UserProfile fromMap(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] as String,
    fullName: map['fullName'] as String? ?? '',
    birthDate: map['birthDate'] is Timestamp
        ? (map['birthDate'] as Timestamp).toDate()
        : null,
    disponibilidad: map['disponibilidad'] as String? ?? 'Mañana',
    cargaAcademica: map['cargaAcademica'] as String? ?? 'Media',
    trabajoEnEquipo: (map['trabajoEnEquipo'] as num?)?.toInt() ?? 3,
    comunicacion: (map['comunicacion'] as num?)?.toInt() ?? 3,
    horasEstudio: (map['horasEstudio'] as num?)?.toInt() ?? 10,
  );
}
