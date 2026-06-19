import 'package:flutter/material.dart';

const _surface = Color(0xFFFBFAF4);
const _border  = Color(0xFFE7E2D5);
const _dot     = Color(0xFF9A978C);

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3C321E).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    final delay = i * 0.2;
                    final progress = (_ctrl.value - delay) % 1.0;
                    double y = 0;
                    if (progress < 0.5) {
                      y = -5 * (progress * 2);
                    } else {
                      y = -5 * (2 - progress * 2);
                    }
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: _dot, shape: BoxShape.circle),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
