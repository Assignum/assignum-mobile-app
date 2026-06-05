import 'package:flutter/material.dart';
import 'package:assignum/chatbox/domain/chat_message.dart';
import 'package:assignum/chatbox/infrastructure/chatbox_service.dart';
import 'package:assignum/chatbox/presentation/widgets/chat_bubble.dart';
import 'package:assignum/chatbox/presentation/widgets/typing_indicator.dart';
import 'package:assignum/shared/presentation/theme/app_theme.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class ChatboxPage extends StatefulWidget {
  const ChatboxPage({super.key});

  @override
  State<ChatboxPage> createState() => _ChatboxPageState();
}

class _ChatboxPageState extends State<ChatboxPage> {
  final ChatboxService _service = ChatboxService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _quickQuestions = [
    '¿Qué es Assignum?',
    '¿Cómo creo una actividad?',
    '¿Cómo invito a miembros?',
    '¿Cuáles son los estados de tareas?',
    '¿Cómo se verifica una tarea?',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await _service.getMessages();
    setState(() {
      _messages = msgs;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _controller.clear();
    
    // Optimistically add user message and set typing state
    setState(() {
      _isTyping = true;
    });
    
    // Force reload history (which saves user message internally and simulates typing wait)
    await _service.getBotResponse(text);
    
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
      await _loadMessages();
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar Chat'),
        content: const Text('¿Estás seguro de que quieres vaciar el historial de la conversación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.upcGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpiar', style: TextStyle(color: AppColors.upcRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.clearHistory();
      await _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PremiumAppBar(
        titleText: 'Chatbot de consultas',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            tooltip: 'Limpiar chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Outer container mirroring user mockup but improved
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.04), width: 1),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(child: Text('No hay mensajes'))
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (i == _messages.length) {
                                  return const TypingIndicator();
                                }
                                return ChatBubble(message: _messages[i]);
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Quick Questions Slider
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _quickQuestions.length,
                itemBuilder: (ctx, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 8.0, top: 4.0),
                    child: ActionChip(
                      label: Text(
                        _quickQuestions[i],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.upcBlack,
                        ),
                      ),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: _isTyping ? null : () => _sendMessage(_quickQuestions[i]),
                    ),
                  );
                },
              ),
            ),

            // Input pill bottom bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Enviar mensaje...',
                                hintStyle: TextStyle(color: Colors.black38),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                                fillColor: Colors.transparent,
                                filled: false,
                              ),
                              onSubmitted: _isTyping ? null : _sendMessage,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: AppColors.upcRed),
                            onPressed: _isTyping ? null : () => _sendMessage(_controller.text),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
