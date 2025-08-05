import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ServiceDB {
  static Future<Database> getDatabase() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'pj_trip.db'),
    );
    return database;
  }

  static Future<void> initTables(Database database) async {
    try {
      await database.execute("""
    CREATE TABLE IF NOT EXISTS travel (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      travelName TEXT,
      placeName TEXT,
      placeLatitude REAL,
      placeLongitude REAL
    )
  """);

      await database.execute("""
    CREATE TABLE IF NOT EXISTS trip (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      travelId INTEGER,
      tripName TEXT,
      tripOrder INTEGER
    )
  """);

      await database.execute("""
    CREATE TABLE IF NOT EXISTS place (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tripId INTEGER,
      placeOrder INTEGER,
      placeName TEXT,
      placeLatitude REAL,
      placeLongitude REAL,
      placeAddress TEXT,
      navigationUrl TEXT
    )
  """);
      debugPrint('travel tables created');
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
