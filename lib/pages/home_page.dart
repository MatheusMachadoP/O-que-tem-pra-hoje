import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oqtemprahoje/services/translation_manager.dart';
import 'package:oqtemprahoje/services/ingredient_translation_service.dart';
import 'package:oqtemprahoje/services/favorites_service.dart';
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
  final FavoritesService _favoritesService = FavoritesService();

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
        List<Map<String, dynamic>> suggestions =
            List<Map<String, dynamic>>.from(data['recipes']);

        // Traduzindo
        final translationManager = TranslationManager();
        final translatedSuggestions = await translationManager
            .translateRecipesList(suggestions, ['title', 'summary']);

        setState(() {
          _suggestions = translatedSuggestions;
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

  void _searchRecipes() async {
    if (_ingredients.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Traduzindo p/ o ingles
        final translatedIngredients =
            await IngredientTranslationService.translateIngredients(
              _ingredients,
            );

        
        if (mounted) Navigator.of(context).pop();

        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipePage(
              ingredients: translatedIngredients,
              originalIngredients: _ingredients,
            ),
          ),
        );
      } catch (e) {
        
        if (mounted) Navigator.of(context).pop();

        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao traduzir ingredientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addToFavorites(Map<String, dynamic> recipe) {
    _favoritesService.addToFavorites(recipe);
    setState(() {}); 
  }

  void _removeFromFavorites(Map<String, dynamic> recipe) {
    _favoritesService.removeFromFavorites(recipe);
    setState(() {}); 
  }

  bool _isFavorite(Map<String, dynamic> recipe) {
    return _favoritesService.isFavorite(recipe);
  }

  void _openRecipeDetail(Map<String, dynamic> recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(
          recipeId: recipe['id'],
          title: recipe['title'],
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
    setState(() {}); 
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
          
          Column(
            children: [
              
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
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
                        // Campo de pesquisa 
                        TextField(
                          controller: _ingredientController,
                          decoration: InputDecoration(
                            hintText: 'Digite um ingrediente',
                            filled: true,
                            fillColor: const Color(0xFFE8F5E9),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFF388E3C),
                              ),
                              onPressed: _addIngredient,
                            ),
                          ),
                          onSubmitted: (_) => _addIngredient(),
                        ),
                        const SizedBox(height: 20),
                        //ingredientes
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
                        //sugestão
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
                        // Sugestões de receitas
                        _loadingSuggestion
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                              )
                            : _suggestions.isEmpty
                            ? const Center(
                                child: Text(
                                  'Erro ao carregar sugestões.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _suggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = _suggestions[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 3,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(15),
                                      onTap: () =>
                                          _openRecipeDetail(suggestion),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Imagem da receita
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(15),
                                                  topRight: Radius.circular(15),
                                                ),
                                            child: suggestion['image'] != null
                                                ? Image.network(
                                                    suggestion['image'],
                                                    height: 180,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    height: 180,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.fastfood,
                                                      size: 50,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                          // Conteúdo receita
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  suggestion['title'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF388E3C),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                if (suggestion['summary'] !=
                                                    null)
                                                  Text(
                                                    suggestion['summary']
                                                        .replaceAll(
                                                          RegExp(r'<[^>]*>'),
                                                          '',
                                                        ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                const SizedBox(height: 8),
                                                // Botão favorito
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        _isFavorite(suggestion)
                                                            ? Icons.favorite
                                                            : Icons
                                                                  .favorite_border,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          if (_isFavorite(
                                                            suggestion,
                                                          )) {
                                                            _removeFromFavorites(
                                                              suggestion,
                                                            );
                                                          } else {
                                                            _addToFavorites(
                                                              suggestion,
                                                            );
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          //  aba dos Favoritos
          _favoritesService.favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma receita favorita ainda.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoritesService.favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favoritesService.favorites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _ingredients.isEmpty ? null : _searchRecipes,
              icon: const Icon(Icons.search),
              label: Text(
                _ingredients.isEmpty
                    ? 'Adicione ingredientes para buscar'
                    : 'Buscar Receitas (${_ingredients.length} ingredientes)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ingredients.isEmpty
                    ? Colors.grey
                    : const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
