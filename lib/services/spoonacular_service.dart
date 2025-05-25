import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpoonacularService {
  static Future<List<dynamic>> getRecipesByIngredients(List<String> ingredients) async {
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
    final ingredientStr = ingredients.join(',');
    final url = Uri.parse(
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientStr&number=10&apiKey=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar receitas');
    }
  }
}
