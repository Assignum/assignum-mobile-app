import 'package:assignum/chatbox/domain/chat_message.dart';
import 'package:assignum/chatbox/domain/i_chatbox_service.dart';
import 'package:assignum/core/infrastructure/api_client.dart';

class ChatboxService implements IChatboxService {
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
  Future<List<ChatMessage>> getMessages() async => List.from(_messages);

  @override
  Future<ChatMessage> getBotResponse(String userText) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userText,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    String replyText;
    try {
      final data = await ApiClient.post('/api/chat/message', {'message': userText})
          as Map<String, dynamic>;
      replyText = data['reply'] as String? ?? _fallbackReply(userText);
    } catch (_) {
      replyText = _fallbackReply(userText);
    }

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
    try {
      await ApiClient.delete('/api/chat/history');
    } catch (_) {}
    _messages.clear();
    _messages.add(ChatMessage(
      id: 'welcome',
      text: '¡Hola! Te responderé las dudas que me comentes acerca de Assignum y cómo coordinar tus proyectos.',
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));
  }

  String _fallbackReply(String text) {
    final q = text.toLowerCase();
    if (q.contains('crear') || q.contains('actividad')) {
      return 'Para crear una actividad ve al Menú Principal y selecciona "Crear Actividad". Ingresa nombre, fecha de entrega y tareas.';
    }
    if (q.contains('invitar') || q.contains('miembro')) {
      return 'Para invitar compañeros entra a la actividad y pulsa "Invitar Miembros". Escribe su correo y confirma.';
    }
    if (q.contains('estado') || q.contains('tarea')) {
      return 'Las tareas tienen 4 estados: Pendiente → En Progreso → Entregado → Verificado. Solo el Líder puede verificar.';
    }
    return 'Puedo ayudarte con creación de actividades, invitar miembros y estados de tareas. ¿Qué necesitas?';
  }
}
