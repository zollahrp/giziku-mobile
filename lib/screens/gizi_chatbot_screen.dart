import 'package:flutter/material.dart';

class GizikuChatbotScreen extends StatefulWidget {
  const GizikuChatbotScreen({super.key});

  @override
  State<GizikuChatbotScreen> createState() => _GizikuChatbotScreenState();
}

class _GizikuChatbotScreenState extends State<GizikuChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // List of chat bubbles: each item is a map {'fromUser': bool, 'text': string}
  final List<Map<String, dynamic>> _messages = [];

  void _sendChat() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'fromUser': true, 'text': text});
      _controller.clear();
    });
    // Simulate bot reply
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _messages.add({'fromUser': false, 'text': "Halo! Ini Gizi Bot."});
        _scrollToBottom();
      });
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _bubble(bool fromUser, String text) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 270),
        decoration: BoxDecoration(
          color: fromUser ? const Color(0xFF2ECC71) : const Color(0xFFF7FDFC),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(fromUser ? 18 : 6),
            bottomRight: Radius.circular(fromUser ? 6 : 18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: fromUser ? Colors.white : const Color(0xFF222222),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2ECC71),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF2ECC71),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(-32),
                bottomRight: Radius.circular(-32),
              ),
            ),
            padding: const EdgeInsets.only(top: 48, bottom: 10),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('logobot.png'), 
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Gizi Bot",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Chat area
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  final msg = _messages[idx];
                  return _bubble(msg['fromUser'], msg['text']);
                },
              ),
            ),
          ),
          // Bottom input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Plus button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FDFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF2ECC71), size: 24),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                // Input field
                Expanded(
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FDFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: InputBorder.none,
                        hintText: "Ketik pesan...",
                        hintStyle: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onSubmitted: (_) => _sendChat(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: _sendChat,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}