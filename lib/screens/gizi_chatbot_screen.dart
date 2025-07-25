import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/chat_message.dart';
import '../../services/bot_service.dart';
import '../../widgets/chat_bubble.dart';

class GizikuChatbotScreen extends StatefulWidget {
  const GizikuChatbotScreen({super.key});

  @override
  State<GizikuChatbotScreen> createState() => _GizikuChatbotScreenState();
}

class _GizikuChatbotScreenState extends State<GizikuChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  Future<void> _sendMessage([String? customText]) async {
    final message = (customText ?? _controller.text).trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: '',
        role: 'user',
        content: message,
        createdAt: DateTime.now(),
      ));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await sendMessageToBot(message); // Hapus token di sini

      setState(() {
        _messages.add(ChatMessage(
          id: '',
          role: 'bot',
          content: reply,
          createdAt: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          id: '',
          role: 'bot',
          content: 'Oops! Gagal menghubungi bot.',
          createdAt: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giziku Chatbot")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text("Bot sedang mengetik..."),
                    );
                  }
                  return ChatBubble(message: _messages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Tulis pesan...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF45B1F9),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
