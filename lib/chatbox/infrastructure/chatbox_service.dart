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

  bool _historyLoaded = false;

  /// La primera vez trae del backend las conversaciones guardadas, para que el historial se
  /// mantenga al cerrar y volver a abrir la app. Si falla, se muestra lo que haya en memoria.
  @override
  Future<List<ChatMessage>> getMessages() async {
    if (!_historyLoaded) {
      try {
        final list = await ApiClient.get('/api/chat/history') as List<dynamic>;
        final exchanges = list.cast<Map<String, dynamic>>()
          ..sort((a, b) =>
              ((a['timestamp'] as num?) ?? 0).compareTo((b['timestamp'] as num?) ?? 0));
        final restored = <ChatMessage>[];
        for (final e in exchanges) {
          final ts = DateTime.fromMillisecondsSinceEpoch((e['timestamp'] as num?)?.toInt() ?? 0);
          final id = e['id'] as String? ?? ts.millisecondsSinceEpoch.toString();
          restored
            ..add(ChatMessage(
                id: '$id-u', text: e['userMessage'] as String? ?? '',
                sender: MessageSender.user, timestamp: ts))
            ..add(ChatMessage(
                id: '$id-b', text: e['botReply'] as String? ?? '',
                sender: MessageSender.bot, timestamp: ts));
        }
        // Mensaje de bienvenida primero, luego el historial y lo enviado en esta sesión
        final sessionMessages = _messages.where((m) => m.id != 'welcome').toList();
        _messages
          ..removeWhere((m) => m.id != 'welcome')
          ..addAll(restored)
          ..addAll(sessionMessages);
        _historyLoaded = true;
      } catch (_) {
        // Sin conexión: se reintenta la próxima vez que se abra el chat
      }
    }
    return List.from(_messages);
  }

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
    _historyLoaded = true;
    _messages.clear();
    _messages.add(ChatMessage(
      id: 'welcome',
      text: _welcomeText,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));
  }
}
