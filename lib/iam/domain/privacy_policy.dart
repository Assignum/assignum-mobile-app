/// Aviso de privacidad de Assignum.
///
/// Si cambia el texto hay que subir [privacyPolicyVersion] aquí y
/// `CURRENT_PRIVACY_POLICY_VERSION` en el backend: a quien aceptó una versión
/// anterior se le vuelve a pedir la aceptación.
const privacyPolicyVersion = '1.0';

class PolicyItem {
  final String data;
  final String purpose;
  const PolicyItem(this.data, this.purpose);
}

class PolicySection {
  final String title;
  final String? body;
  final List<PolicyItem> items;
  const PolicySection(this.title, {this.body, this.items = const []});
}

/// Qué datos se piden y para qué se usa cada uno (resumen que se muestra en el registro).
const policyDataUses = <PolicyItem>[
  PolicyItem('Nombre y correo',
      'Identificarte ante tu equipo y enviarte invitaciones y avisos.'),
  PolicyItem('Fecha de nacimiento',
      'Solo se muestra en tu perfil. No se usa para asignar tareas.'),
  PolicyItem('Habilidades, experiencia y horas disponibles',
      'Calcular qué tareas se ajustan mejor a ti. El modelo recibe solo estos valores, sin tu nombre ni tu correo.'),
  PolicyItem('Tareas, comentarios y archivos',
      'Mostrar el avance de la actividad a los integrantes de tu equipo.'),
  PolicyItem('Mensajes al asistente',
      'Responder tus consultas. Se envía solo el texto, sin tu correo.'),
];

const privacyPolicySections = <PolicySection>[
  PolicySection(
    'Responsable',
    body:
        'Assignum es un proyecto académico. El equipo de desarrollo es responsable '
        'del tratamiento de los datos que registras en la aplicación, conforme a la '
        'Ley N.º 29733, Ley de Protección de Datos Personales, y su reglamento.',
  ),
  PolicySection('Datos que recopilamos y para qué', items: policyDataUses),
  PolicySection(
    'Qué no hacemos',
    body:
        'No pedimos sexo, distrito ni otros datos sensibles. No usamos tu edad para '
        'asignar tareas. No vendemos ni compartimos tus datos con fines comerciales.',
  ),
  PolicySection(
    'Quién ve tus datos',
    body:
        'Solo los integrantes de las actividades a las que perteneces ven tu nombre y '
        'tus tareas. Tus habilidades y horas disponibles no se muestran a otros '
        'estudiantes. Los datos se guardan en Firebase (Google Cloud) y el modelo de '
        'recomendación se ejecuta en Render.',
  ),
  PolicySection(
    'Decisiones automatizadas',
    body:
        'El reparto de tareas es una recomendación. El líder del equipo puede '
        'revisarlo, modificarlo o redistribuirlo en cualquier momento.',
  ),
  PolicySection(
    'Tus derechos',
    body:
        'Puedes consultar y corregir tus datos desde tu perfil, y eliminar tu cuenta '
        'desde Perfil > Eliminar mi cuenta. Al eliminarla se borran tu perfil, tus '
        'avisos y tu historial del asistente, y sales de los grupos de los que eras '
        'miembro.',
  ),
  PolicySection(
    'Cambios en este aviso',
    body:
        'Si el aviso cambia, la app te pedirá aceptarlo de nuevo antes de seguir '
        'editando tu perfil.',
  ),
];
