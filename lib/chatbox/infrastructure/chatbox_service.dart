import 'package:assignum/chatbox/domain/chat_message.dart';
import 'package:assignum/chatbox/domain/i_chatbox_service.dart';

class ChatboxService implements IChatboxService {
  // Singleton pattern for easy use across pages
  static final ChatboxService _instance = ChatboxService._internal();
  factory ChatboxService() => _instance;
  ChatboxService._internal();

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'welcome',
      text: '¡Hola! Te responderé las dudas que me comentes acerca de Assignum y cómo coordinar tus proyectos.',
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  Future<List<ChatMessage>> getMessages() async {
    // Return a copy to avoid modifications outside
    return List.from(_messages);
  }

  @override
  Future<ChatMessage> getBotResponse(String userText) async {
    // Add user message to history
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userText,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    // Simulate typing delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final replyText = _generateReply(userText);

    final botMsg = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: replyText,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
    _messages.add(botMsg);

    return botMsg;
  }

  @override
  Future<void> clearHistory() async {
    _messages.clear();
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text: '¡Hola! Te responderé las dudas que me comentes acerca de Assignum y cómo coordinar tus proyectos.',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      ),
    );
  }

  String _generateReply(String text) {
    final query = text.toLowerCase().trim();

    if (query.contains('hola') || query.contains('buenos dias') || query.contains('buenas tardes') || query.contains('buenas noches')) {
      return '¡Hola! Soy tu asistente inteligente de **Assignum**. Estoy aquí para ayudarte a resolver cualquier duda sobre el funcionamiento de la aplicación, estados de tareas, invitaciones o creación de actividades. ¿En qué te puedo colaborar hoy?';
    }

    if (query.contains('qué es') || query.contains('que es') || query.contains('assignum') || query.contains('funciona') || query.contains('para qué sirve')) {
      return '¡Hola! **Assignum** es tu organizador y asistente inteligente de actividades y tareas grupales. Te permite estructurar proyectos académicos o laborales, asignar responsabilidades individuales a cada miembro, registrar enlaces o evidencias de entregas, y realizar una verificación formal para asegurar la calidad de cada entregable.';
    }

    if (query.contains('crear') || query.contains('nueva') || query.contains('actividad') || query.contains('creo') || query.contains('cómo crear')) {
      return 'Para crear una actividad:\n\n'
          '1. Ve al **Menú Principal** y selecciona **"Crear Actividad"**.\n'
          '2. Ingresa un nombre descriptivo y establece la **Fecha de entrega**.\n'
          '3. Añade opcionalmente un enlace (ej. Google Drive) para adjuntar documentos del proyecto.\n'
          '4. Define una o más tareas iniciales ingresando sus nombres y presiona el botón "+" para agregarlas.\n'
          '5. Finalmente, presiona el botón **"Crear Actividad"** abajo para guardarla.';
    }

    if (query.contains('invitar') || query.contains('miembros') || query.contains('miembro') || query.contains('correo') || query.contains('agregar') || query.contains('compañero')) {
      return 'Para invitar a tu equipo:\n\n'
          '1. Ve a **"Tus Actividades"** en el inicio y presiona **"Ver"** en la actividad elegida.\n'
          '2. Haz clic en **"Invitar Miembros"**.\n'
          '3. Escribe el correo electrónico exacto de tu compañero/a y presiona **"Agregar Correo"**.\n'
          '4. Se le enviará una invitación. Tu compañero/a recibirá una alerta en su panel de notificaciones dentro de la app para unirse al proyecto.';
    }

    if (query.contains('estado') || query.contains('pendiente') || query.contains('en progreso') || query.contains('entregado') || query.contains('status') || query.contains('tareas')) {
      return 'Las tareas en Assignum pasan por 4 estados clave:\n\n'
          '1. 🔴 **Pendiente**: Tarea recién creada, lista para ser iniciada.\n'
          '2. 🟡 **En Progreso**: El miembro asignado ya está trabajando en ella.\n'
          '3. 🔵 **Entregado**: El miembro completó la tarea y subió comentarios o enlaces para su revisión.\n'
          '4. 🟢 **Verificado**: El creador de la actividad revisó y dio su visto bueno a la entrega. ¡Esto actualiza el progreso general!';
    }

    if (query.contains('verificar') || query.contains('verifico') || query.contains('verificado') || query.contains('aprobar') || query.contains('revisar')) {
      return 'La verificación asegura la calidad del trabajo. Solo el **creador de la actividad** (quien la creó originalmente) puede verificar una tarea:\n\n'
          '1. Abre la actividad y presiona sobre la tarea que esté en estado **"Entregado"**.\n'
          '2. En los detalles, revisa los comentarios o archivos subidos por el miembro encargado.\n'
          '3. Si todo está correcto, cambia el estado a **"Verificado"** y presiona **Guardar**.\n'
          '4. Esto sumará automáticamente al porcentaje de progreso general de la actividad.';
    }

    if (query.contains('upc') || query.contains('universidad') || query.contains('ciclo')) {
      return '¡Hola compañero/a de la **UPC**! Assignum fue concebido para ayudar a los estudiantes de la UPC a coordinar trabajos grupales eficientemente, evitando las entregas a última hora y asegurando un reparto equitativo del trabajo mediante métricas claras.';
    }

    // Default general response
    return 'Entiendo tu consulta sobre "$text", pero no tengo una respuesta exacta registrada en mi sistema de guías rápidas.\n\nPuedo ayudarte con temas como:\n'
        '• 📝 **Creación de actividades** y tareas\n'
        '• 👥 **Invitación de miembros** por correo electrónico\n'
        '• 🔄 El ciclo de vida de los **estados de tareas** (Pendiente, En Progreso, Entregado, Verificado)\n'
        '• ✅ Cómo **verificar tareas** si eres el líder.\n\n'
        'Prueba seleccionando una de las preguntas sugeridas abajo o escribe palabras clave como "crear actividad" o "invitar".';
  }
}
