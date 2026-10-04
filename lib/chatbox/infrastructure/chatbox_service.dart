import 'package:assignum/chatbox/domain/chat_message.dart';
import 'package:assignum/chatbox/domain/i_chatbox_service.dart';
import 'package:assignum/core/infrastructure/api_client.dart';

const _welcomeText =
    '¡Hola! Puedo decirte tus **tareas pendientes**, cómo va una **actividad** o **agregar una tarea** por ti '
    '(por ejemplo: "agrega la tarea hacer diapositivas a Proyecto de Física"). También respondo dudas sobre Assignum.';

const _connectionErrorText =
    'No pude conectarme con el asistente. Revisa tu conexión e inténtalo de nuevo en unos segundos.';

class ChatboxService implements IChatboxService {
  static final ChatboxService _instance = ChatboxService._internal();
  factory ChatboxService() => _instance;
  ChatboxService._internal();

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'welcome',
      text: _welcomeText,
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
      replyText = data['reply'] as String? ?? _connectionErrorText;
    } catch (_) {
      // Las respuestas (incluidas las acciones sobre tareas) las genera el backend con Azure CLU;
      // sin conexión no hay una respuesta local fiable que dar.
      replyText = _connectionErrorText;
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
      text: _welcomeText,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));
  }
}
