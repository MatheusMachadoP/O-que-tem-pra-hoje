import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oqtemprahoje/services/translation_manager.dart';
import 'package:oqtemprahoje/services/gemini_translation_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final int recipeId;
  final String title;
  final Map<String, dynamic> recipe;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
    required this.title,
    required this.recipe,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic>? _recipeDetail;
  bool _isLoading = true;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _fetchRecipeDetail();
  }

  Future<void> _fetchRecipeDetail() async {
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
    final url =
        'https://api.spoonacular.com/recipes/${widget.recipeId}/information?includeNutrition=false&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> recipeData = json.decode(response.body);

      // Limpar HTML dos dados antes da tradução
      final geminiService = GeminiService();
      if (recipeData['instructions'] != null) {
        recipeData['instructions'] = geminiService.removeHtmlTags(
          recipeData['instructions'].toString(),
        );
      }
      if (recipeData['summary'] != null) {
        recipeData['summary'] = geminiService.removeHtmlTags(
          recipeData['summary'].toString(),
        );
      }

      final translationManager = TranslationManager();

      print('🔍 DEBUG: Traduzindo receita ${widget.recipeId}');
      print('📄 Título original: ${recipeData['title']}');
      print(
        '📝 Instruções originais: ${recipeData['instructions']?.substring(0, 100) ?? 'null'}...',
      );

      final translatedRecipe = await translationManager.translateRecipeFields(
        recipeData,
        ['title', 'instructions'], 
      );

      print('✅ Título traduzido: ${translatedRecipe['title']}');
      print(
        '✅ Instruções traduzidas: ${translatedRecipe['instructions']?.substring(0, 100) ?? 'null'}...',
      );

      // Traduzindo ingredientes
      if (translatedRecipe['extendedIngredients'] != null) {
        List<dynamic> ingredients = translatedRecipe['extendedIngredients'];
        for (int i = 0; i < ingredients.length; i++) {
          try {
            final original = ingredients[i]['original'];
            if (original != null && original is String && original.isNotEmpty) {
              final translatedText = await translationManager
                  .translateRecipeField(
                    widget.recipeId,
                    'ingredient_$i',
                    original,
                  );
              ingredients[i]['original'] = translatedText;
            }
          } catch (e) {
            print('Erro ao traduzir ingrediente $i: $e');
          }
        }
      }

      setState(() {
        _recipeDetail = translatedRecipe;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavoriteToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipeDetail == null
          ? const Center(child: Text('Erro ao carregar detalhes.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_recipeDetail!['image'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_recipeDetail!['image']),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _recipeDetail!['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ingredientes:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...?_recipeDetail!['extendedIngredients']?.map<Widget>((ing) {
                    return Text("- ${ing['original']}");
                  }).toList(),
                  const SizedBox(height: 20),
                  const Text(
                    'Instruções:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recipeDetail!['instructions'] ??
                        'Sem instruções disponíveis.',
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
    );
  }
}
