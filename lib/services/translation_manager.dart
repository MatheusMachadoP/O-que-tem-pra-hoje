import 'package:oqtemprahoje/services/openai_translation_service.dart';
import 'package:oqtemprahoje/services/translation_database_service.dart';

class TranslationManager {
  final TranslationDatabaseService _dbService = TranslationDatabaseService();

  String _removeHtmlTags(String text) {
    final RegExp htmlTagRegex = RegExp(r'<[^>]*>');
    String cleanText = text.replaceAll(htmlTagRegex, ' ');
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanText;
  }

  Future<Map<String, dynamic>> translateRecipeFields(
    Map<String, dynamic> recipe,
    List<String> fieldsToTranslate,
  ) async {
    final recipeId = recipe['id'] as int;

    final existingTranslations = await _dbService.getRecipeTranslations(
      recipeId,
    );

    Map<String, String> toTranslate = {};
    Map<String, String> originalTexts = {};

    for (String field in fieldsToTranslate) {
      if (recipe[field] != null && recipe[field].toString().isNotEmpty) {
        // Se já existe tradução no banco, usar ela
        if (existingTranslations.containsKey(field)) {
          recipe[field] = existingTranslations[field];
        } else {
          // Adicionar à lista para traduzir
          String originalText = recipe[field].toString();
          toTranslate[field] = originalText;
          originalTexts[field] = originalText;
        }
      }
    }

    // Se há campos para traduzir, fazer a tradução
    if (toTranslate.isNotEmpty) {
      try {
        for (String field in toTranslate.keys) {
          String originalText = toTranslate[field]!;

          // Traduzindo
          String translatedText = await OpenAITranslationService.translateText(
            originalText,
            'Portuguese',
          );

          recipe[field] = translatedText;

          await _dbService.saveTranslation(
            recipeId,
            field,
            originalText,
            translatedText,
          );
        }
      } catch (e) {
        print('Erro na tradução: $e');
        for (String field in toTranslate.keys) {
          recipe[field] = _removeHtmlTags(toTranslate[field]!);
        }
      }
    }

    return recipe;
  }

  // Traduzir a grande fucking lista de receitas
  Future<List<Map<String, dynamic>>> translateRecipesList(
    List<Map<String, dynamic>> recipes,
    List<String> fieldsToTranslate,
  ) async {
    List<Map<String, dynamic>> translatedRecipes = [];

    for (var recipe in recipes) {
      final translatedRecipe = await translateRecipeFields(
        recipe,
        fieldsToTranslate,
      );
      translatedRecipes.add(translatedRecipe);
    }

    return translatedRecipes;
  }

  // Traduzir campo específico de uma receita
  Future<String> translateRecipeField(
    int recipeId,
    String fieldName,
    String originalText,
  ) async {
    // Verificar se já existe tradução no banco
    final existingTranslation = await _dbService.getTranslation(
      recipeId,
      fieldName,
    );

    if (existingTranslation != null) {
      return existingTranslation;
    }

    try {
      final translatedText = await OpenAITranslationService.translateText(
        originalText,
        'Portuguese',
      );

      await _dbService.saveTranslation(
        recipeId,
        fieldName,
        originalText,
        translatedText,
      );

      return translatedText;
    } catch (e) {
      print('Erro na tradução do campo $fieldName: $e');
      return _removeHtmlTags(originalText);
    }
  }

  Future<List<String>> translateInstructions(
    int recipeId,
    List<String> instructions,
  ) async {
    List<String> translatedInstructions = [];

    for (int i = 0; i < instructions.length; i++) {
      String fieldName = 'instruction_$i';
      String originalText = instructions[i];

      String translatedText = await translateRecipeField(
        recipeId,
        fieldName,
        originalText,
      );

      translatedInstructions.add(translatedText);
    }

    return translatedInstructions;
  }

  Future<List<String>> translateIngredients(
    int recipeId,
    List<String> ingredients,
  ) async {
    List<String> translatedIngredients = [];

    for (int i = 0; i < ingredients.length; i++) {
      String fieldName = 'ingredient_$i';
      String originalText = ingredients[i];

      String translatedText = await translateRecipeField(
        recipeId,
        fieldName,
        originalText,
      );

      translatedIngredients.add(translatedText);
    }

    return translatedIngredients;
  }
}
