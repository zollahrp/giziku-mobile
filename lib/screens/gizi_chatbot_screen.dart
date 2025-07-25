import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/chat_message.dart';
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

  @override
  void initState() {
    super.initState();
    _addBotMessage("Halo! Aku GiziBot dari Giziku 🤖\nAku bisa bantu rekomendasi makanan sehat sesuai kondisi kamu!");
  }

  void _addBotMessage(String content) {
    setState(() {
      _messages.add(ChatMessage(
        id: '',
        role: 'bot',
        content: content,
        createdAt: DateTime.now(),
      ));
      _isTyping = false;
    });
    _scrollToBottom();
  }

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

    await Future.delayed(const Duration(seconds: 1)); // efek delay bot

    String reply;
    if (message.toLowerCase().contains('makan')) {
      reply = "Coba deh konsumsi sayur hijau, ikan, dan buah lokal 🍎🐟\nMau resep sederhana?";
    } else if (message.toLowerCase().contains('malnutrisi')) {
      reply = "Malnutrisi bisa dicegah dengan pola makan seimbang dan pemantauan berat badan.";
    } else if (message.toLowerCase().contains('halo') || message.toLowerCase().contains('hai')) {
      reply = "Hai juga! 👋 Ada yang bisa aku bantu?";
    } else {
      reply = "Hmm... aku masih belajar nih, bisa coba tanya yang lain?";
    }

    _addBotMessage(reply);
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
