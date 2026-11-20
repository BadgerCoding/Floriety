import 'dart:convert';
import 'dart:io';

import 'api_service.dart';
import 'auth_service.dart';

/// Talks to YOUR server (which holds the Groq key), not to Groq directly.
/// Public method names are unchanged, so no screen needs editing.
class GroqService {
  static String get _token {
    final t = AuthService().token;
    if (t == null || t.isEmpty) {
      throw Exception('Please log in again.');
    }
    return t;
  }

  static String _stripFences(String content) =>
      content.replaceAll('```json', '').replaceAll('```', '').trim();

  /// Scans a flower image (from file) and returns the flower details.
  static Future<Map<String, String>> scanFlower(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

    final content = await ApiService.aiScan(
      _token,
      base64Encode(bytes),
      mimeType,
    );

    try {
      final Map<String, dynamic> parsed = jsonDecode(_stripFences(content));
      return parsed.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {
        'isFlower': 'true',
        'name': 'Unknown Flower',
        'scientific': 'N/A',
        'family': 'N/A',
        'variety_appearance': 'N/A',
        'origin': 'N/A',
        'habitat': 'N/A',
        'allergen': 'N/A',
        'disease': 'N/A',
        'care_list':
            '1. Provide adequate water\n2. Ensure proper sunlight\n3. Use well-draining soil',
        'description': content,
      };
    }
  }

  /// Sends a chat message with conversation history and returns the AI reply.
  static Future<String> chat(List<Map<String, String>> messages) {
    return ApiService.aiChat(_token, messages);
  }

  /// Identifies a flower from a text description.
  static Future<Map<String, String>> identifyFlower(String description) async {
    final content = await ApiService.aiIdentify(_token, description);
    try {
      final Map<String, dynamic> parsed = jsonDecode(_stripFences(content));
      return parsed.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {
        'name': 'Mystery Flower',
        'scientific': 'Unknown species',
        'imagePrompt': 'beautiful flower botanical illustration',
        'description': content,
      };
    }
  }

  /// Generates a full care guide for a flower.
  static Future<String> generateCareGuide(Map<String, String> flowerData) {
    return ApiService.aiCareGuide(_token, flowerData);
  }
}
