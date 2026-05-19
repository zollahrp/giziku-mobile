import 'package:flutter/material.dart';
import 'package:giziku/screens/chat_memory.dart';

import '../../models/chat_message.dart';
import '../../services/giziku_chatbot_service.dart';
import '../../widgets/chat_bubble.dart';

class GizikuChatbotScreen extends StatefulWidget {
  const GizikuChatbotScreen({super.key});

  @override
  State<GizikuChatbotScreen> createState() => _GizikuChatbotScreenState();
}

class _GizikuChatbotScreenState extends State<GizikuChatbotScreen> {
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final GizikuChatbotService _chatService = GizikuChatbotService();

  List<ChatMessage> _messages = ChatMemory.messages;

  bool _isTyping = false;

  bool _isIntroTyping = false;

  @override
  void initState() {
    super.initState();

    if (!ChatMemory.introShown) {
      ChatMemory.introShown = true;

      _showWelcomeMessage();
    }
  }

  void _addBotMessage(String content) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: '',
          role: 'bot',
          content: content,
          createdAt: DateTime.now(),
        ),
      );

      _isTyping = false;
      ChatMemory.messages = _messages;
    });

    _scrollToBottom();
  }

  Future<void> _showWelcomeMessage() async {
    setState(() {
      _isIntroTyping = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isIntroTyping = false;
    });

    _addBotMessage(
      "Halo, saya GiziBot.\nSaya siap membantu menganalisis nutrisi, pola makan, dan progress kesehatan Kamu secara personal.",
    );
  }

  Future<void> _sendMessage([String? customText]) async {
    final message = (customText ?? _controller.text).trim();

    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: '',
          role: 'user',
          content: message,
          createdAt: DateTime.now(),
        ),
      );

      _controller.clear();

      ChatMemory.messages = _messages;

      _isTyping = true;
    });

    _scrollToBottom();

    final response = await _chatService.sendMessage(message);

    _addBotMessage(response);
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

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),

      child: Container(
        margin: const EdgeInsets.only(right: 10),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: Colors.grey.shade200),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF2ECC71)),

            const SizedBox(width: 8),

            Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF5F7FB),

        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),

                gradient: const LinearGradient(
                  colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                ),

                boxShadow: [
                  BoxShadow(
                    color: Color(0x332ECC71),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),

              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "GiziBot",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.4,
                  ),
                ),

                SizedBox(height: 2),
              ],
            ),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),

            child: GestureDetector(
              onTap: () {
                setState(() {
                  _messages.clear();

                  ChatMemory.messages = [];

                  ChatMemory.introShown = false;
                });

                _showWelcomeMessage();
              },

              child: Container(
                padding: const EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: const Icon(
                  Icons.edit_square,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ================= AI STATUS =================
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),

              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(18),

                border: Border.all(color: Colors.grey.shade200),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),

                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                      ),
                    ),

                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "GiziBot",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          "Terhubung dengan data nutrisi harian Kamu",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 10,
                    height: 10,

                    decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            // ================= CHAT =================
            Expanded(
              child: ListView.builder(
                controller: _scrollController,

                padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),

                itemCount:
                    _messages.length +
                    (_isTyping ? 1 : 0) +
                    (_isIntroTyping ? 1 : 0),

                itemBuilder: (context, index) {
                  int currentIndex = index;

                  // ================= INTRO TYPING =================

                  if (_isIntroTyping) {
                    if (currentIndex == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,

                              decoration: const BoxDecoration(
                                color: Color(0xFF2ECC71),
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Text(
                              "GiziBot sedang memulai...",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    currentIndex--;
                  }

                  // ================= CHAT MESSAGE =================

                  if (currentIndex < _messages.length) {
                    return ChatBubble(message: _messages[currentIndex]);
                  }

                  currentIndex -= _messages.length;

                  // ================= NORMAL AI TYPING =================

                  if (_isTyping && currentIndex == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),

                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,

                            decoration: const BoxDecoration(
                              color: Color(0xFF2ECC71),
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            "GiziBot sedang menganalisis...",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // ================= QUICK QUESTION =================
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal: 12),

              child: Row(
                children: [
                  _buildSuggestionChip("Ringkasan nutrisi hari ini"),

                  _buildSuggestionChip("Analisis protein 7 hari"),

                  _buildSuggestionChip("Insight pola makan saya"),

                  _buildSuggestionChip("Apakah konsumsi saya sudah ideal?"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ================= INPUT =================
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),

              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(26),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,

                      decoration: InputDecoration(
                        hintText: "Tanyakan nutrisi atau pola makan...",

                        hintStyle: TextStyle(color: Colors.grey.shade500),

                        border: InputBorder.none,

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),

                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  GestureDetector(
                    onTap: _sendMessage,

                    child: Container(
                      width: 46,
                      height: 46,

                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                        ),

                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
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
