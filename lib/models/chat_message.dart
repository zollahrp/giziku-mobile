class ChatMessage {
  final int id;
  final String sender; // 'user' or 'bot'
  final String text;
  final String time;
  final String? image;
  final bool hasWidget;
  final Map<String, dynamic>? widgetData;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.image,
    this.hasWidget = false,
    this.widgetData,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Backward compatibility getters
  String get role => sender;
  String get content => text;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'role': sender,
      'text': text,
      'content': text,
      'time': time,
      if (image != null) 'image': image,
      'hasWidget': hasWidget,
      if (widgetData != null) 'widgetData': widgetData,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    int parsedId;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else {
      parsedId = int.tryParse(json['id']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch;
    }

    DateTime parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ChatMessage(
      id: parsedId,
      sender: json['sender']?.toString() ?? json['role']?.toString() ?? 'user',
      text: json['text']?.toString() ?? json['content']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      image: json['image']?.toString(),
      hasWidget: json['hasWidget'] == true,
      widgetData: json['widgetData'] != null ? Map<String, dynamic>.from(json['widgetData']) : null,
      createdAt: parsedDate,
    );
  }
}

class ChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'updatedAt': updatedAt,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json, String docId) {
    DateTime parsedDate;
    if (json['updatedAt'] != null) {
      final val = json['updatedAt'];
      if (val is DateTime) {
        parsedDate = val;
      } else if (val.runtimeType.toString().contains('Timestamp')) {
        parsedDate = val.toDate();
      } else {
        parsedDate = DateTime.tryParse(val.toString()) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    final rawMsgs = (json['messages'] as List<dynamic>?) ?? [];
    final parsedMsgs = rawMsgs
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();

    return ChatSession(
      id: docId,
      title: json['title'] ?? 'Obrolan Baru',
      updatedAt: parsedDate,
      messages: parsedMsgs,
    );
  }
}
