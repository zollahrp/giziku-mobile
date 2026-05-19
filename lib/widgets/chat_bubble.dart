import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 12,
        ),

        padding: const EdgeInsets.all(14),

        constraints: const BoxConstraints(
          maxWidth: 320,
        ),

        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF2ECC71)
              : Colors.white,

          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              )
            : MarkdownBody(
                data: message.content,

                selectable: true,

                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),

                  strong: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),

                  h1: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),

                  h2: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),

                  listBullet: const TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
    );
  }
}