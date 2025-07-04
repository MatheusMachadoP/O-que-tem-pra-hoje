import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class GeminiService {
  final apiKey = dotenv.env['GEMINI_API_KEY'];

  /// Limpa a string de resposta da API, removendo blocos de código Markdown
  /// e espaços em branco extras que podem quebrar o `jsonDecode`.
  String _sanitizeResponse(String rawResponse) {
    // Remove os marcadores ```json e ``` do início e do fim da string.
    final sanitized = rawResponse
        .replaceAll(RegExp(r'```json\n?|```'), '')
        .trim();
    return sanitized;
  }

  /// Remove tags HTML de uma string
  String removeHtmlTags(String text) {
    if (text.isEmpty) return text;

    // Remove tags HTML comuns
    final htmlTagRegex = RegExp(r'<[^>]*>', multiLine: true, dotAll: true);
    String cleanText = text.replaceAll(htmlTagRegex, '');

    // Remove entidades HTML comuns
    cleanText = cleanText
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Remove múltiplos espaços e quebras de linha desnecessárias
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleanText;
  }

  Future<dynamic> traduzirJsonArray(
    List<Map<String, dynamic>> jsonArray,
  ) async {
    // Limpar HTML dos dados antes de traduzir
    final cleanedJsonArray = jsonArray.map((item) {
      final cleanedItem = Map<String, dynamic>.from(item);

      // Limpar campos específicos que podem conter HTML
      if (cleanedItem['instructions'] != null) {
        cleanedItem['instructions'] = removeHtmlTags(
          cleanedItem['instructions'].toString(),
        );
      }
      if (cleanedItem['summary'] != null) {
        cleanedItem['summary'] = removeHtmlTags(
          cleanedItem['summary'].toString(),
        );
      }

      return cleanedItem;
    }).toList();
    // Prompt mais direto, focando na tarefa de tradução.
    final prompt =
        '''
Traduza os campos de texto (título, ingredientes, instruções) para cada receita no array JSON a seguir para o português do Brasil. 

INSTRUÇÕES IMPORTANTES:
1. Mantenha a estrutura JSON exata
2. Se encontrar tags HTML (como <b>, </b>, <i>, </i>, <p>, </p>, <ol>, </ol>, <li>, </li>, etc.), REMOVA completamente essas tags
3. Mantenha apenas o texto limpo, sem nenhuma marcação HTML
4. Traduza apenas o texto, preservando quebras de linha naturais
5. Retorne apenas o JSON traduzido, sem texto adicional

JSON:
${jsonEncode(cleanedJsonArray)}
''';

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      // Adicionando a configuração de geração para controlar a saída.
      "generationConfig": {
        "temperature": 0.5,
        "response_mime_type": "application/json",
        // Aumentando o limite de tokens para evitar que a resposta seja cortada.
        "maxOutputTokens": 8192,
      },
    });

    try {
      final response = await http
          .post(
            // Usando a API v1beta, que é mais estável para recursos como 'response_mime_type'.
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 120),
          ); // Timeout para evitar esperas infinitas.

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Checagem de segurança para ver se a resposta foi cortada.
        final finishReason = responseBody['candidates'][0]['finishReason'];
        if (finishReason == 'MAX_TOKENS') {
          throw Exception(
            'A resposta foi cortada por exceder o limite de tokens. Considere enviar menos dados por vez.',
          );
        }

        final rawContent =
            responseBody['candidates'][0]['content']['parts'][0]['text'];

        // Limpa a resposta antes de tentar decodificar.
        final sanitizedContent = _sanitizeResponse(rawContent);

        return jsonDecode(sanitizedContent);
      } else {
        throw Exception(
          'Erro na API Gemini: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('A requisição ao Gemini excedeu o tempo limite.');
    } catch (e) {
      // Relança o erro para ser tratado pela camada que chamou o serviço.
      rethrow;
    }
  }
}
