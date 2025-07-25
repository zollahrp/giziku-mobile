// class ChatSession {
//   final String id;
//   final String? title;

//   ChatSession({required this.id, this.title});

//   factory ChatSession.fromJson(Map<String, dynamic> json) {
//     return ChatSession(
//       id: json['id'],
//       title: json['title'],
//     );
//   }
// }
class ChatSession {
  final String id;
  final String? title;
  final DateTime? createdAt;

  ChatSession({
    required this.id,
    this.title,
    this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'created_at': createdAt?.toIso8601String(),
  };
}
