import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ServiceDB {
  static Future<Database> getDatabase() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'pj_trip.db'),
    );
    return database;
  }
}
