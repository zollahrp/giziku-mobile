import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/chat_message.dart';
import '../services/giziku_chatbot_service.dart';
import '../widgets/chat_bubble.dart';

class GizifyChatbotScreen extends StatefulWidget {
  const GizifyChatbotScreen({super.key});

  @override
  State<GizifyChatbotScreen> createState() => _GizifyChatbotScreenState();
}

class _GizifyChatbotScreenState extends State<GizifyChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GizifyChatbotService _chatService = GizifyChatbotService();
  final ImagePicker _picker = ImagePicker();

  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _userName = "User";

  // Sessions and Active Chat
  List<ChatSession> _chatSessions = [];
  String? _currentChatId;
  List<ChatMessage> _messages = [];

  bool _isTyping = false;
  bool _isLoadingHistory = true;

  // Thinking Animation & Timer State
  late AnimationController _animController;
  Timer? _thinkingTimer;
  int _thinkingSeconds = 1;

  // Selected Image for attachment
  String? _selectedImageBase64;
  File? _selectedImageFile;

  // Suggestions with professional icons
  final List<Map<String, dynamic>> _suggestions = [
    {"icon": Icons.egg_alt_outlined, "text": "Sarapan Tinggi Protein"},
    {"icon": Icons.local_fire_department_outlined, "text": "Cara Defisit Kalori"},
    {"icon": Icons.eco_outlined, "text": "Camilan Lemak Sehat"},
    {"icon": Icons.fitness_center_outlined, "text": "Kebutuhan Protein Harian"},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _initChatbot();
  }

  @override
  void dispose() {
    _thinkingTimer?.cancel();
    _animController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startThinkingTimer() {
    _thinkingTimer?.cancel();
    _thinkingSeconds = 1;
    _thinkingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isTyping) {
        setState(() {
          _thinkingSeconds++;
        });
        _scrollToBottom();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopThinkingTimer() {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;
  }

  Future<void> _initChatbot() async {
    final uid = currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      // 1. Fetch user name
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data() ?? {};
        final fullName = data['name'] ?? currentUser?.displayName ?? "User";
        _userName = fullName.toString().split(' ').first;
      }

      // 2. Fetch Chat History from Firestore with 7-day cleanup
      await _fetchChatHistory(uid);
    } catch (e) {
      debugPrint("Error init chatbot: $e");
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // Fetch Firestore Sessions with 7-day retention
  Future<void> _fetchChatHistory(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chats')
          .orderBy('updatedAt', descending: true)
          .get();

      final List<ChatSession> loaded = [];
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      for (var doc in snap.docs) {
        final session = ChatSession.fromJson(doc.data(), doc.id);
        if (session.updatedAt.isBefore(sevenDaysAgo)) {
          // Auto cleanup older than 7 days (matching web)
          doc.reference.delete();
          continue;
        }
        loaded.add(session);
      }

      if (mounted) {
        setState(() {
          _chatSessions = loaded;
          _isLoadingHistory = false;
        });

        if (loaded.isNotEmpty) {
          _selectChat(loaded.first.id);
        } else {
          _startNewChat();
        }
      }
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        _startNewChat();
      }
    }
  }

  Future<void> _startNewChat() async {
    setState(() {
      _currentChatId = null;
      _messages = [];
      _isTyping = true;
    });
    _startThinkingTimer();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    _stopThinkingTimer();

    setState(() {
      _isTyping = false;
      _messages = [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          sender: "bot",
          text:
              "Halo $_userName! Saya Gizibot, asisten nutrisi pintarmu. Mau tanya saran menu sehat, hitung kalori, atau tips gizi hari ini?",
          time: DateFormat('HH:mm').format(DateTime.now()),
        ),
      ];
    });
    _scrollToBottom();
  }

  void _selectChat(String chatId) {
    final session = _chatSessions.firstWhere(
      (s) => s.id == chatId,
      orElse: () => ChatSession(
        id: chatId,
        title: "Obrolan Baru",
        updatedAt: DateTime.now(),
        messages: [],
      ),
    );

    setState(() {
      _currentChatId = session.id;
      _messages = List.from(session.messages);
    });

    _scrollToBottom();
  }

  Future<void> _deleteChat(String chatId) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chats')
          .doc(chatId)
          .delete();

      setState(() {
        _chatSessions.removeWhere((s) => s.id == chatId);
        if (_currentChatId == chatId) {
          if (_chatSessions.isNotEmpty) {
            _selectChat(_chatSessions.first.id);
          } else {
            _startNewChat();
          }
        }
      });
    } catch (e) {
      debugPrint("Error deleting chat: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Str = base64Encode(bytes);

        setState(() {
          _selectedImageFile = File(picked.path);
          _selectedImageBase64 = "data:image/jpeg;base64,$base64Str";
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBase64 = null;
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final textToSend = (customText ?? _controller.text).trim();
    final imageToSend = _selectedImageBase64;

    if (textToSend.isEmpty && imageToSend == null) return;
    final uid = currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    final userMsg = ChatMessage(
      id: now.millisecondsSinceEpoch,
      sender: "user",
      text: textToSend,
      time: timeStr,
      image: imageToSend,
    );

    setState(() {
      _messages.add(userMsg);
      _controller.clear();
      _selectedImageBase64 = null;
      _selectedImageFile = null;
      _isTyping = true;
    });

    _startThinkingTimer();
    _scrollToBottom();

    // Firestore Reference
    final chatsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats');

    String activeChatId = _currentChatId ?? '';

    try {
      // 1. Save / Update User Turn in Firestore
      if (activeChatId.isEmpty) {
        final newDoc = chatsRef.doc();
        activeChatId = newDoc.id;
        _currentChatId = activeChatId;

        final newSession = ChatSession(
          id: activeChatId,
          title: textToSend.length > 25
              ? "${textToSend.substring(0, 25)}..."
              : (textToSend.isNotEmpty ? textToSend : "Diskusi Foto"),
          updatedAt: now,
          messages: List.from(_messages),
        );

        _chatSessions.insert(0, newSession);
        await newDoc.set({
          'id': activeChatId,
          'title': newSession.title,
          'updatedAt': FieldValue.serverTimestamp(),
          'messages': _messages.map((m) => m.toJson()).toList(),
        });
      } else {
        await chatsRef.doc(activeChatId).update({
          'updatedAt': FieldValue.serverTimestamp(),
          'messages': _messages.map((m) => m.toJson()).toList(),
        });

        final idx = _chatSessions.indexWhere((s) => s.id == activeChatId);
        if (idx != -1) {
          final updated = ChatSession(
            id: activeChatId,
            title: _chatSessions[idx].title,
            updatedAt: now,
            messages: List.from(_messages),
          );
          _chatSessions.removeAt(idx);
          _chatSessions.insert(0, updated);
        }
      }

      // 2. Call Gemini Service with full history
      final botResponse = await _chatService.sendChat(messages: _messages);

      final botMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        sender: "bot",
        text: botResponse.text,
        time: DateFormat('HH:mm').format(DateTime.now()),
        hasWidget: botResponse.hasWidget,
        widgetData: botResponse.widgetData,
      );

      _stopThinkingTimer();
      if (mounted) {
        setState(() {
          _messages.add(botMsg);
          _isTyping = false;
        });
        _scrollToBottom();
      }

      // 3. Update Firestore with Bot Turn
      await chatsRef.doc(activeChatId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': _messages.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
      _stopThinkingTimer();
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch,
              sender: "bot",
              text:
                  "Maaf, koneksi ke Gizibot sedang bermasalah. Silakan coba lagi.",
              time: DateFormat('HH:mm').format(DateTime.now()),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Date category helper (today, yesterday, last7Days)
  String _categorizeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Hari Ini";
    if (checkDate == yesterday) return "Kemarin";
    return "7 Hari Terakhir";
  }

  @override
  Widget build(BuildContext context) {
    final hasSuggestions = !_isTyping && _messages.length <= 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildHistoryDrawer(),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Session Banner (managed by GiziBot AI)
            _buildSessionBanner(),

            // Chat Messages Scroll Area
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        return ChatBubble(message: _messages[index]);
                      } else {
                        return _buildTypingIndicator();
                      }
                    },
                  ),

                  // Suggestions Overlay (when new chat)
                  if (hasSuggestions)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: _buildSuggestionsOverlay(),
                    ),
                ],
              ),
            ),

            // Chat Input Area with Image Preview
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // APP BAR
  // ==========================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (ctx) {
          return IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF1E293B)),
            tooltip: "Riwayat Obrolan",
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          );
        },
      ),
      title: Row(
        children: [
          // Bot Avatar with Pulse Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1EAB57), Color(0xFF127236)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1EAB57).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                ),
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Gizibot",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                "AKTIF & SIAP MEMBANTU",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1EAB57),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, color: Color(0xFF1EAB57), size: 26),
          tooltip: "Obrolan Baru",
          onPressed: _startNewChat,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ==========================================
  // SESSION BANNER
  // ==========================================
  Widget _buildSessionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "SESI INI DIKELOLA OLEH GIZIBOT",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TYPING & THINKING INDICATOR (ANIMASI MIKIR)
  // ==========================================
  Widget _buildTypingIndicator() {
    String thoughtStage;
    if (_thinkingSeconds <= 1) {
      thoughtStage = _messages.isEmpty
          ? "Menyiapkan Gizibot..."
          : "Menganalisis pertanyaan...";
    } else if (_thinkingSeconds <= 3) {
      thoughtStage = _messages.isEmpty
          ? "Menghubungkan asisten nutrisi..."
          : "Mengkalkulasi nutrisi & gizi...";
    } else if (_thinkingSeconds <= 5) {
      thoughtStage = "Meracik saran terbaik Gizify...";
    } else {
      thoughtStage = "Menyusun jawaban lengkap...";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot Avatar with Animated Glowing Pulse
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final double pulse = 0.5 + 0.5 * sin(_animController.value * 2 * pi);
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1EAB57), Color(0xFF127236)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1EAB57).withOpacity(0.25 + 0.25 * pulse),
                      blurRadius: 8 + 6 * pulse,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 19),
                ),
              );
            },
          ),
          const SizedBox(width: 10),

          // Thinking Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Timer Badge: Gizibot • Mikir 1s, 2s, 3s...
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Gizibot",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "•",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                      const SizedBox(width: 5),

                      // Animated Timer Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                final double tilt = sin(_animController.value * 2 * pi) * 0.25;
                                return Transform.rotate(
                                  angle: tilt,
                                  child: const Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 11,
                                    color: Color(0xFF1EAB57),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                "Mikir ${_thinkingSeconds}s",
                                key: ValueKey<int>(_thinkingSeconds),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Thinking Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1EAB57).withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Rotating Sparkle Icon
                          RotationTransition(
                            turns: _animController,
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: Color(0xFF1EAB57),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Thought stage caption with cross-fade
                          Flexible(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                thoughtStage,
                                key: ValueKey<String>(thoughtStage),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3 Bouncing Dots (Jitter-free Transform.translate)
                          _buildBouncingDots(),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Animated Micro Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const SizedBox(
                          width: 180,
                          height: 3,
                          child: LinearProgressIndicator(
                            backgroundColor: Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation(Color(0xFF1EAB57)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBouncingDots() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return SizedBox(
          height: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (i) {
              final double delay = i * 0.2;
              final double t = (_animController.value - delay) % 1.0;
              final double bounce = sin(t * pi).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, -bounce * 4),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFF86EFAC),
                      const Color(0xFF1EAB57),
                      bounce,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ==========================================
  // SUGGESTIONS OVERLAY
  // ==========================================
  Widget _buildSuggestionsOverlay() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sug = _suggestions[index];
          return GestureDetector(
            onTap: () => _sendMessage(sug['text']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    sug['icon'] as IconData,
                    size: 14,
                    color: const Color(0xFF1EAB57),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (sug['text'] as String?) ?? '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // INPUT AREA (ATTACHMENT & SEND)
  // ==========================================
  Widget _buildInputArea() {
    final hasContent = _controller.text.trim().isNotEmpty || _selectedImageFile != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview thumbnail (before sending)
          if (_selectedImageFile != null) ...[
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1EAB57), width: 2),
                    image: DecorationImage(
                      image: FileImage(_selectedImageFile!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: GestureDetector(
                    onTap: _removeSelectedImage,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Form Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach Image Button
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF64748B)),
                  tooltip: "Lampirkan Foto Makanan",
                  onPressed: _showImagePickerOptions,
                ),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: "Tanya seputar gizi, resep, atau kalori...",
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                // Send Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 4),
                  child: GestureDetector(
                    onTap: hasContent && !_isTyping ? () => _sendMessage() : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasContent
                            ? const Color(0xFF1EAB57)
                            : const Color(0xFF0F172A),
                        shape: BoxShape.circle,
                        boxShadow: hasContent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF1EAB57).withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        hasContent ? Icons.send_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Disclaimer
          const Center(
            child: Text(
              "Gizibot dapat membuat kesalahan. Verifikasi informasi medis penting.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Foto Makanan",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Kamera",
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildPickerOption(
                    icon: Icons.photo_library_rounded,
                    label: "Galeri",
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Icon(icon, color: const Color(0xFF1EAB57), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HISTORY DRAWER (SIDEBAR KANAN PERSIS WEB)
  // ==========================================
  Widget _buildHistoryDrawer() {
    final Map<String, List<ChatSession>> grouped = {
      "Hari Ini": _chatSessions
          .where((s) => _categorizeDate(s.updatedAt) == "Hari Ini")
          .toList(),
      "Kemarin": _chatSessions
          .where((s) => _categorizeDate(s.updatedAt) == "Kemarin")
          .toList(),
      "7 Hari Terakhir": _chatSessions
          .where((s) => _categorizeDate(s.updatedAt) == "7 Hari Terakhir")
          .toList(),
    };

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.history_rounded, color: Color(0xFF1EAB57), size: 22),
                          SizedBox(width: 8),
                          Text(
                            "Riwayat Obrolan",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Retention notice banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Obrolan disimpan selama 7 hari.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button: OBROLAN BARU
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _startNewChat();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_rounded, size: 16, color: Color(0xFF1EAB57)),
                          SizedBox(width: 6),
                          Text(
                            "OBROLAN BARU",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Grouped History Sessions List
            Expanded(
              child: _isLoadingHistory
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1EAB57)),
                    )
                  : _chatSessions.isEmpty
                      ? const Center(
                          child: Text(
                            "Belum ada riwayat obrolan.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          children: grouped.entries.map((entry) {
                            if (entry.value.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: Text(
                                    entry.key.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                ...entry.value.map((session) {
                                  final isSelected = session.id == _currentChatId;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFA7F3D0)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(
                                        session.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w900
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat('HH:mm').format(session.updatedAt),
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 9,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        onPressed: () => _deleteChat(session.id),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _selectChat(session.id);
                                      },
                                    ),
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
            ),

            // Pro Promo Card at bottom of Drawer
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF15803D)),
                      SizedBox(width: 6),
                      Text(
                        "Gizibot Pro Unlimited",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF14532D),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Dapatkan analisis makanan tak terbatas dan konsultasi gizi mendalam.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF166534),
                      height: 1.3,
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
