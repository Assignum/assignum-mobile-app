import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/chatbox/domain/chat_message.dart';

const _surface  = Color(0xFFFBFAF4);
const _border   = Color(0xFFE7E2D5);
const _text     = Color(0xFF21201B);
const _primary  = Color(0xFFDC2F26);

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _primary : _surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 18),
                ),
                border: isUser ? null : Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3C321E).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildContent(isUser),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isUser) {
    final baseStyle = GoogleFonts.hankenGrotesk(
      color: isUser ? Colors.white : _text,
      fontSize: 14.5,
      height: 1.5,
    );
    return _parseMarkdown(message.text, baseStyle, isUser);
  }

  // Renders **bold** as red+bold for bot, white+bold for user
  Widget _parseMarkdown(String text, TextStyle base, bool isUser) {
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final spans = <TextSpan>[];
    int last = 0;

    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: base.copyWith(
          fontWeight: FontWeight.w700,
          color: isUser ? Colors.white : _primary,
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(
      text: TextSpan(style: base, children: spans),
    );
  }
}
