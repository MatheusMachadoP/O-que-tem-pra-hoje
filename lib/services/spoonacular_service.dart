import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'gemini_translation_service.dart'; // Adicione este import

class SpoonacularService {
  static Future<List<dynamic>> getRecipesByIngredients(List<String> ingredients) async {
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
    final ingredientStr = ingredients.join(',');
    final url = Uri.parse(
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientStr&number=10&apiKey=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> recipes = jsonDecode(response.body);

      final gemini = GeminiService(); // PFV Deus permita dê certo de primeira
      final translated = await gemini.traduzirJsonArray(
        recipes.cast<Map<String, dynamic>>(),
      );

      return translated;
    } else {
      throw Exception('Erro ao buscar receitas');
    }
  }
}