import 'package:flutter/material.dart';
import 'recipe_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        title: const Text("O que tem pra hoje?"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _ingredientController,
              decoration: InputDecoration(
                hintText: 'Digite um ingrediente',
                filled: true,
                fillColor: const Color(0xFFE8F5E9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _ingredients.map((ingredient) {
                return Chip(
                  label: Text(ingredient, style: const TextStyle(color: Colors.white)),
                  backgroundColor: const Color(0xFF66BB6A),
                  deleteIcon: const Icon(Icons.close, color: Colors.white),
                  onDeleted: () => _removeIngredient(ingredient),
                );
              }).toList(),
            ),
            if (_ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: _clearAllIngredients,
                  icon: const Icon(Icons.delete_forever, color: Color(0xFF388E3C)),
                  label: const Text(
                    'Limpar ingredientes',
                    style: TextStyle(color: Color(0xFF388E3C)),
                  ),
                ),
              ),
            const Spacer(),
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
    );
  }
}
