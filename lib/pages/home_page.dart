import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'recipe_page.dart';
import 'recipe_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  final List<Map<String, dynamic>> _favorites = [];

  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestion = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions() async {
    setState(() => _loadingSuggestion = true);
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
    final url =
        'https://api.spoonacular.com/recipes/random?number=2&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(data['recipes']);
          _loadingSuggestion = false;
        });
      } else {
        setState(() => _loadingSuggestion = false);
      }
    } catch (e) {
      setState(() => _loadingSuggestion = false);
    }
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty && !_ingredients.contains(text)) {
      setState(() {
        _ingredients.add(text);
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
  }

  void _clearAllIngredients() {
    setState(() {
      _ingredients.clear();
    });
  }

  void _searchRecipes() {
    if (_ingredients.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipePage(ingredients: _ingredients),
        ),
      );
    }
  }

  void _addToFavorites(Map<String, dynamic> recipe) {
    if (!_favorites.any((fav) => fav['id'] == recipe['id'])) {
      setState(() {
        _favorites.add(recipe);
      });
    }
  }

  void _removeFromFavorites(Map<String, dynamic> recipe) {
    setState(() {
      _favorites.removeWhere((fav) => fav['id'] == recipe['id']);
    });
  }

  bool _isFavorite(Map<String, dynamic> recipe) {
    return _favorites.any((fav) => fav['id'] == recipe['id']);
  }

  Future<void> _openRecipeDetail(Map<String, dynamic> recipe) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailPage(
          recipeId: recipe['id'],
          title: recipe['title'] ?? '',
          recipe: recipe,
          isFavorite: _isFavorite(recipe),
          onFavoriteToggle: () {
            setState(() {
              if (_isFavorite(recipe)) {
                _removeFromFavorites(recipe);
              } else {
                _addToFavorites(recipe);
              }
            });
          },
        ),
      ),
    );
    setState(() {}); // Atualiza favoritos ao voltar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        title: const Text("O que tem pra hoje?"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: "Buscar Receitas"),
            Tab(icon: Icon(Icons.favorite), text: "Favoritos"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Primeira aba: Buscar Receitas
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título para buscar receita
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 12.0,
                        left: 4.0,
                        top: 8.0,
                      ),
                      child: Text(
                        'Vamos ver o que tem pra hoje?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ),
                  ),
                  // Campo de pesquisa para procurar um ingrediente
                  TextField(
                    controller: _ingredientController,
                    decoration: InputDecoration(
                      hintText: 'Digite um ingrediente',
                      filled: true,
                      fillColor: const Color(0xFFE8F5E9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF388E3C)),
                        onPressed: _addIngredient,
                      ),
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                  const SizedBox(height: 20),
                  // Chips de ingredientes
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: _ingredients.map((ingredient) {
                      return Chip(
                        label: Text(
                          ingredient,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF66BB6A),
                        deleteIcon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        onDeleted: () => _removeIngredient(ingredient),
                      );
                    }).toList(),
                  ),
                  if (_ingredients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextButton.icon(
                        onPressed: _clearAllIngredients,
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Color(0xFF388E3C),
                        ),
                        label: const Text(
                          'Limpar ingredientes',
                          style: TextStyle(color: Color(0xFF388E3C)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Título da sugestão
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.0, left: 4.0),
                      child: Text(
                        'Bateu a fome? Que tal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ),
                  ),
                  // Duas sugestões de receita
                  _loadingSuggestion
                      ? const Center(child: CircularProgressIndicator())
                      : _suggestions.isEmpty
                      ? const Text('Erro ao carregar sugestões.')
                      : Column(
                          children: _suggestions.map((suggestion) {
                            return GestureDetector(
                              onTap: () => _openRecipeDetail(suggestion),
                              child: Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          suggestion['image'] ?? '',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              suggestion['title'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              suggestion['summary'] != null
                                                  ? suggestion['summary']
                                                        .replaceAll(
                                                          RegExp(r'<[^>]*>'),
                                                          '',
                                                        )
                                                  : '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            IconButton(
                                              icon: Icon(
                                                _isFavorite(suggestion)
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (_isFavorite(suggestion)) {
                                                    _removeFromFavorites(
                                                      suggestion,
                                                    );
                                                  } else {
                                                    _addToFavorites(suggestion);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _searchRecipes,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar Receitas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Aba Favoritos
          _favorites.isEmpty
              ? const Center(child: Text('Nenhuma receita favorita ainda.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: fav['image'] != null
                              ? Image.network(
                                  fav['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.fastfood),
                        ),
                        title: Text(fav['title'] ?? ''),
                        subtitle: fav['summary'] != null
                            ? Text(
                                fav['summary'].replaceAll(
                                  RegExp(r'<[^>]*>'),
                                  '',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFromFavorites(fav),
                        ),
                        onTap: () => _openRecipeDetail(fav),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
