import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/chatbox/domain/chat_message.dart';
import 'package:assignum/chatbox/infrastructure/chatbox_service.dart';
import 'package:assignum/chatbox/presentation/widgets/chat_bubble.dart';
import 'package:assignum/chatbox/presentation/widgets/typing_indicator.dart';

// ── Tokens ─────────────────────────────────────────────────────────────
const _bg           = Color(0xFFF4F2EA);
const _surface      = Color(0xFFFBFAF4);
const _surface2     = Color(0xFFFFFFFF);
const _surfaceInset = Color(0xFFF0EDE2);
const _text2        = Color(0xFF6E6B61);
const _text3        = Color(0xFF9A978C);
const _border       = Color(0xFFE7E2D5);
const _primary      = Color(0xFFDC2F26);

class ChatboxPage extends StatefulWidget {
  const ChatboxPage({super.key});

  @override
  State<ChatboxPage> createState() => _ChatboxPageState();
}

class _ChatboxPageState extends State<ChatboxPage> {
  final _service          = ChatboxService();
  final _controller       = TextEditingController();
  final _scrollController = ScrollController();

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
    if (mounted) setState(() => _messages = msgs);
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
    setState(() => _isTyping = true);
    await _service.getBotResponse(text);
    if (mounted) {
      setState(() => _isTyping = false);
      await _loadMessages();
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _surface2,
        title: Text('Limpiar chat',
            style: GoogleFonts.hankenGrotesk(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF21201B))),
        content: Text('¿Seguro que quieres borrar el historial?',
            style: GoogleFonts.hankenGrotesk(color: _text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.hankenGrotesk(
                    color: _text2, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: Text('Limpiar',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
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
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('Empieza una conversación',
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 14, color: _text3)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
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
          // Quick questions
          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _quickQuestions.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8, top: 4),
                child: GestureDetector(
                  onTap: _isTyping
                      ? null
                      : () => _sendMessage(_quickQuestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      _quickQuestions[i],
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _text2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2723), Color(0xFF46413A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Color(0xFFF6F3EA), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Bot avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              // Title + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assignum',
                        style: GoogleFonts.hankenGrotesk(
                          color: const Color(0xFFF6F3EA),
                          fontSize: 16, fontWeight: FontWeight.w700,
                        )),
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text('En línea',
                            style: GoogleFonts.hankenGrotesk(
                              color: const Color(0xFFF6F3EA).withValues(alpha: 0.6),
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              // Clear chat
              GestureDetector(
                onTap: _clearChat,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Color(0xFFF6F3EA), size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: _bg,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 18),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 14, color: const Color(0xFF21201B)),
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: GoogleFonts.hankenGrotesk(
                              fontSize: 14, color: _text3),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onSubmitted:
                            _isTyping ? null : _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isTyping
                  ? null
                  : () => _sendMessage(_controller.text),
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _isTyping
                      ? _surfaceInset
                      : _primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isTyping ? _text3 : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
