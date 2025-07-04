import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAITranslationService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static String? get _apiKey => dotenv.env['OPENAI_API_KEY'];
  static String get _model => dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo';

  static String _removeHtmlTags(String text) {
    final RegExp htmlTagRegex = RegExp(r'<[^>]*>');
    String cleanText = text.replaceAll(htmlTagRegex, ' ');

    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleanText;
  }

  static Future<String> translateText(
    String text,
    String targetLanguage,
  ) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenAI API key not found in environment variables');
    }

    String cleanText = _removeHtmlTags(text);

    if (cleanText.isEmpty) {
      return '';
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional translator specializing in food and cooking content. '
                  'Translate the given text to $targetLanguage accurately, maintaining the cooking context. '
                  'Return ONLY the translated text without any HTML tags, formatting, or additional comments. '
                  'If the text contains cooking terms, use appropriate culinary terminology in the target language.',
            },
            {
              'role': 'user',
              'content': 'Translate this text to $targetLanguage: $cleanText',
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String translatedText = data['choices'][0]['message']['content']
            .toString()
            .trim();

        translatedText = _removeHtmlTags(translatedText);

        print('OpenAI Translation - Model: $_model');
        print('OpenAI Translation - Original: $cleanText');
        print('OpenAI Translation - Translated: $translatedText');

        return translatedText;
      } else {
        print('OpenAI API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to translate text: ${response.statusCode}');
      }
    } catch (e) {
      print('OpenAI Translation Error: $e');
      return cleanText;
    }
  }

  static Future<Map<String, String>> translateRecipeFields({
    required String title,
    required String summary,
    required List<String> instructions,
    required List<String> ingredients,
    String targetLanguage = 'Portuguese',
  }) async {
    try {
      final translatedTitle = await translateText(title, targetLanguage);
      final translatedSummary = await translateText(summary, targetLanguage);

      List<String> translatedInstructions = [];
      for (String instruction in instructions) {
        final translated = await translateText(instruction, targetLanguage);
        translatedInstructions.add(translated);
      }

      List<String> translatedIngredients = [];
      for (String ingredient in ingredients) {
        final translated = await translateText(ingredient, targetLanguage);
        translatedIngredients.add(translated);
      }

      return {
        'title': translatedTitle,
        'summary': translatedSummary,
        'instructions': translatedInstructions.join('|'),
        'ingredients': translatedIngredients.join('|'),
      };
    } catch (e) {
      print('Error translating recipe fields: $e');
      return {
        'title': _removeHtmlTags(title),
        'summary': _removeHtmlTags(summary),
        'instructions': instructions.map((i) => _removeHtmlTags(i)).join('|'),
        'ingredients': ingredients.map((i) => _removeHtmlTags(i)).join('|'),
      };
    }
  }

  static String getCurrentModel() {
    return _model;
  }

  static bool isConfigured() {
    return _apiKey != null && _apiKey!.isNotEmpty;
  }
}
