import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oqtemprahoje/services/translation_manager.dart';
import 'package:oqtemprahoje/services/favorites_service.dart';
import 'recipe_detail_page.dart';

class RecipePage extends StatefulWidget {
  final List<String> ingredients;
  final List<String>? originalIngredients;

  const RecipePage({
    super.key,
    required this.ingredients,
    this.originalIngredients,
  });

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<dynamic> _recipes = [];
  bool _isLoading = true;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
    final ingredients = widget.ingredients.join(',');
    final url =
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredients&number=10&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> recipes = List<Map<String, dynamic>>.from(
        data,
      );

      final translationManager = TranslationManager();
      final translatedRecipes = await translationManager.translateRecipesList(
        recipes,
        ['title'], // Traduzir apenas o título
      );

      setState(() {
        _recipes = translatedRecipes;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receitas Encontradas")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: recipe['image'] != null
                          ? Image.network(
                              recipe['image'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.fastfood),
                    ),
                    title: Text(
                      recipe['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _favoritesService.isFavorite(recipe)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _favoritesService.toggleFavorite(recipe);
                            });
                          },
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailPage(
                            recipeId: recipe['id'],
                            title: recipe['title'],
                            recipe: recipe,
                            isFavorite: _favoritesService.isFavorite(recipe),
                            onFavoriteToggle: () {
                              setState(() {
                                _favoritesService.toggleFavorite(recipe);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
