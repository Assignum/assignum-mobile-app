import 'package:assignum/chatbox/domain/chat_message.dart';

abstract class IChatboxService {
  Future<List<ChatMessage>> getMessages();
  Future<ChatMessage> getBotResponse(String userText);
  Future<void> clearHistory();
}
