import 'package:oqtemprahoje/services/openai_translation_service.dart';

class IngredientTranslationService {
  // Dicionário de ingredientes
  static final Map<String, String> _commonIngredients = {
    // Carnes e Proteínas
    'carne': 'meat',
    'frango': 'chicken',
    'peixe': 'fish',
    'porco': 'pork',
    'boi': 'beef',
    'carneiro': 'lamb',
    'ovo': 'egg',
    'ovos': 'eggs',

    // Vegetais
    'tomate': 'tomato',
    'cebola': 'onion',
    'alho': 'garlic',
    'batata': 'potato',
    'cenoura': 'carrot',
    'brócolis': 'broccoli',
    'abobrinha': 'zucchini',
    'berinjela': 'eggplant',
    'pimentão': 'bell pepper',
    'alface': 'lettuce',
    'espinafre': 'spinach',
    'couve': 'kale',
    'repolho': 'cabbage',
    'pepino': 'cucumber',
    'cogumelo': 'mushroom',
    'champignon': 'mushroom',

    // Frutas
    'maçã': 'apple',
    'banana': 'banana',
    'laranja': 'orange',
    'limão': 'lemon',
    'abacaxi': 'pineapple',
    'manga': 'mango',
    'uva': 'grape',
    'morango': 'strawberry',
    'pêssego': 'peach',
    'pêra': 'pear',
    'melancia': 'watermelon',
    'melão': 'melon',

    // Grãos e Cereais
    'arroz': 'rice',
    'feijão': 'beans',
    'lentilha': 'lentils',
    'grão de bico': 'chickpeas',
    'quinoa': 'quinoa',
    'aveia': 'oats',
    'trigo': 'wheat',
    'milho': 'corn',
    'cevada': 'barley',

    // Laticínios
    'leite': 'milk',
    'queijo': 'cheese',
    'iogurte': 'yogurt',
    'manteiga': 'butter',
    'creme de leite': 'cream',
    'requeijão': 'cream cheese',

    // Temperos e Ervas
    'sal': 'salt',
    'pimenta': 'pepper',
    'açúcar': 'sugar',
    'azeite': 'olive oil',
    'óleo': 'oil',
    'vinagre': 'vinegar',
    'manjericão': 'basil',
    'orégano': 'oregano',
    'tomilho': 'thyme',
    'alecrim': 'rosemary',
    'salsa': 'parsley',
    'coentro': 'cilantro',
    'canela': 'cinnamon',
    'cominho': 'cumin',
    'páprica': 'paprika',
    'açafrão': 'saffron',

    // Massas e Pães
    'macarrão': 'pasta',
    'espaguete': 'spaghetti',
    'penne': 'penne',
    'lasanha': 'lasagna',
    'pão': 'bread',
    'farinha': 'flour',
    'massa': 'dough',

    // Outros
    'água': 'water',
    'caldo': 'broth',
    'molho': 'sauce',
    'sopa': 'soup',
    'salada': 'salad',
  };

  static Future<String> translateIngredient(String ingredient) async {
    final lowerIngredient = ingredient.toLowerCase().trim();

    if (_commonIngredients.containsKey(lowerIngredient)) {
      return _commonIngredients[lowerIngredient]!;
    }

    // Se não encontrou no dicionário, usar OpenAI
    try {
      final translated = await OpenAITranslationService.translateText(
        ingredient,
        'English',
      );
      return translated;
    } catch (e) {
      print('Erro ao traduzir ingrediente "$ingredient": $e');
      return ingredient;
    }
  }

  static Future<List<String>> translateIngredients(
    List<String> ingredients,
  ) async {
    List<String> translatedIngredients = [];

    for (String ingredient in ingredients) {
      String translated = await translateIngredient(ingredient);
      translatedIngredients.add(translated);
      print('Ingrediente traduzido: $ingredient -> $translated');
    }

    return translatedIngredients;
  }
}
