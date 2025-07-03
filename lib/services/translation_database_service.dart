import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TranslationDatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'translations.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        field_name TEXT NOT NULL,
        original_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(recipe_id, field_name)
      )
    ''');
  }

  // Salvar tradução
  Future<void> saveTranslation(
    int recipeId,
    String fieldName,
    String originalText,
    String translatedText,
  ) async {
    final db = await database;
    await db.insert('translations', {
      'recipe_id': recipeId,
      'field_name': fieldName,
      'original_text': originalText,
      'translated_text': translatedText,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Buscar tradução específica
  Future<String?> getTranslation(int recipeId, String fieldName) async {
    final db = await database;
    final result = await db.query(
      'translations',
      columns: ['translated_text'],
      where: 'recipe_id = ? AND field_name = ?',
      whereArgs: [recipeId, fieldName],
    );

    if (result.isNotEmpty) {
      return result.first['translated_text'] as String;
    }
    return null;
  }

  // Buscar todas as traduções de uma receita
  Future<Map<String, String>> getRecipeTranslations(int recipeId) async {
    final db = await database;
    final result = await db.query(
      'translations',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );

    Map<String, String> translations = {};
    for (var row in result) {
      translations[row['field_name'] as String] =
          row['translated_text'] as String;
    }
    return translations;
  }

  // Salvar múltiplas traduções de uma receita
  Future<void> saveRecipeTranslations(
    int recipeId,
    Map<String, String> originalTexts,
    Map<String, String> translatedTexts,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (var fieldName in originalTexts.keys) {
      if (translatedTexts.containsKey(fieldName)) {
        batch.insert('translations', {
          'recipe_id': recipeId,
          'field_name': fieldName,
          'original_text': originalTexts[fieldName],
          'translated_text': translatedTexts[fieldName],
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    await batch.commit();
  }

  // Limpar todas as traduções (útil para desenvolvimento)
  Future<void> clearAllTranslations() async {
    final db = await database;
    await db.delete('translations');
  }
}
