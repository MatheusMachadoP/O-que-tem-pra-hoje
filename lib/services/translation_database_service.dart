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

  Future<void> clearAllTranslations() async {
    final db = await database;
    await db.delete('translations');
    print('🗑️ Banco de traduções limpo completamente!');
  }

  Future<void> clearRecipeTranslations(int recipeId) async {
    final db = await database;
    await db.delete(
      'translations',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    print('🗑️ Traduções da receita $recipeId removidas!');
  }

  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'translations.db');
  }

  Future<void> debugPrintAllTranslations() async {
    final db = await database;
    final result = await db.query('translations', orderBy: 'created_at DESC');

    print('=== TODAS AS TRADUÇÕES ===');
    print('Total de registros: ${result.length}');

    for (var row in result) {
      print('ID: ${row['id']}');
      print('Recipe ID: ${row['recipe_id']}');
      print('Campo: ${row['field_name']}');
      print('Original: ${row['original_text']}');
      print('Traduzido: ${row['translated_text']}');
      print('Data: ${row['created_at']}');
      print('---');
    }

    String dbPath = await getDatabasePath();
    print('Caminho do banco: $dbPath');
  }

  Future<void> debugDatabaseStatus() async {
    try {
      final db = await database;

      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='translations'",
      );

      print('=== STATUS DO BANCO ===');
      print('Tabela translations existe: ${tables.isNotEmpty}');

      if (tables.isNotEmpty) {
        final count = await db.rawQuery(
          'SELECT COUNT(*) as count FROM translations',
        );
        print('Total de traduções: ${count.first['count']}');

        final countByRecipe = await db.rawQuery('''
          SELECT recipe_id, COUNT(*) as count 
          FROM translations 
          GROUP BY recipe_id
        ''');

        print('Traduções por receita:');
        for (var row in countByRecipe) {
          print('  Recipe ${row['recipe_id']}: ${row['count']} traduções');
        }
      }

      print('Caminho: ${await getDatabasePath()}');
      print('=====================');
    } catch (e) {
      print('Erro ao verificar banco: $e');
    }
  }

  Future<Map<int, int>> getTranslationCountByRecipe() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT recipe_id, COUNT(*) as count 
      FROM translations 
      GROUP BY recipe_id
    ''');

    Map<int, int> counts = {};
    for (var row in result) {
      counts[row['recipe_id'] as int] = row['count'] as int;
    }
    return counts;
  }

  Future<List<Map<String, dynamic>>> getAllTranslations() async {
    final db = await database;
    return await db.query('translations', orderBy: 'created_at DESC');
  }
}
