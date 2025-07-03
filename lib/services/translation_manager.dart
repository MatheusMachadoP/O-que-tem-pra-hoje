import 'package:oqtemprahoje/services/gemini_translation_service.dart';
import 'package:oqtemprahoje/services/translation_database_service.dart';

class TranslationManager {
  final GeminiService _geminiService = GeminiService();
  final TranslationDatabaseService _dbService = TranslationDatabaseService();

  // Traduzir múltiplos campos de uma receita
  Future<Map<String, dynamic>> translateRecipeFields(
    Map<String, dynamic> recipe,
    List<String> fieldsToTranslate,
  ) async {
    final recipeId = recipe['id'] as int;

    // Buscar traduções existentes no banco
    final existingTranslations = await _dbService.getRecipeTranslations(
      recipeId,
    );

    // Separar campos que precisam ser traduzidos
    Map<String, String> toTranslate = {};
    Map<String, String> originalTexts = {};

    for (String field in fieldsToTranslate) {
      if (recipe[field] != null && recipe[field].toString().isNotEmpty) {
        // Se já existe tradução no banco, usar ela
        if (existingTranslations.containsKey(field)) {
          recipe[field] = existingTranslations[field];
        } else {
          // Adicionar à lista para traduzir
          toTranslate[field] = recipe[field].toString();
          originalTexts[field] = recipe[field].toString();
        }
      }
    }

    // Se há campos para traduzir, fazer a tradução
    if (toTranslate.isNotEmpty) {
      try {
        // Converter para formato que o Gemini aceita
        List<Map<String, dynamic>> toTranslateList = [toTranslate];

        // Traduzir com Gemini
        final translated = await _geminiService.traduzirJsonArray(
          toTranslateList,
        );

        if (translated.isNotEmpty) {
          final translatedData = translated[0];
          if (translatedData is Map<String, dynamic>) {
            final translatedFields = translatedData;

            // Atualizar recipe com traduções
            for (String field in toTranslate.keys) {
              if (translatedFields.containsKey(field)) {
                recipe[field] = translatedFields[field];
              }
            }

            // Salvar traduções no banco
            await _dbService.saveRecipeTranslations(
              recipeId,
              originalTexts,
              Map<String, String>.from(translatedFields),
            );
          }
        }
      } catch (e) {
        print('Erro na tradução: $e');
        // Em caso de erro, manter textos originais
      }
    }

    return recipe;
  }

  // Traduzir uma lista de receitas
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
      // Traduzir com Gemini
      final translated = await _geminiService.traduzirJsonArray([
        {fieldName: originalText},
      ]);

      if (translated.isNotEmpty) {
        final translatedValue = translated[0][fieldName];
        if (translatedValue != null && translatedValue is String) {
          final translatedText = translatedValue;

          // Salvar no banco
          await _dbService.saveTranslation(
            recipeId,
            fieldName,
            originalText,
            translatedText,
          );

          return translatedText;
        }
      }
    } catch (e) {
      print('Erro na tradução do campo $fieldName: $e');
    }

    // Em caso de erro, retornar texto original
    return originalText;
  }
}
