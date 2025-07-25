import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> sendMessageToBot(String message, String token) async {
  final response = await http.post(
    Uri.parse('https://kqt1clq7-8000.asse.devtunnels.ms/api/chatbot/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'message': message}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['reply'] ?? 'No reply';
  } else {
    throw Exception('Failed to get reply from bot');
  }
}
