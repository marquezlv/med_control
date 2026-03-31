import 'database_helper.dart';
import 'database_seed.dart';

class DatabaseInitializer {
  static Future<void> initialize() async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseSeed.seedIfNeeded(db);
  }
}
