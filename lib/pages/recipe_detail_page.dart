import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecipeDetailPage extends StatefulWidget {
  final int recipeId;
  final String title;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
    required this.title,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  Map<String, dynamic>? _recipeDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetail();
  }

  Future<void> _fetchRecipeDetail() async {
    final apiKey = dotenv.env['SPOONACULAR_API_KEY'];
    final url =
        'https://api.spoonacular.com/recipes/${widget.recipeId}/information?includeNutrition=false&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _recipeDetail = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      const Text('Ingredientes:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...?_recipeDetail!['extendedIngredients']?.map<Widget>((ing) {
                        return Text("- ${ing['original']}");
                      }).toList(),
                      const SizedBox(height: 20),
                      const Text('Instruções:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _recipeDetail!['instructions'] ?? 'Sem instruções disponíveis.',
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
    );
  }
}
