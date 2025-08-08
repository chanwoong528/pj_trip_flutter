import 'package:flutter/material.dart';
import 'package:pj_trip/db/service_db.dart';
import 'package:pj_trip/db/model/model_place.dart';

class ServicePlace {
  static Future<List<ModelPlace>> getPlaces(int tripId) async {
    final database = await ServiceDB.getDatabase();
    final places = await database.query(
      'place',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'placeOrder ASC',
    );
    debugPrint('places: $places');
    return places
        .map(
          (e) => ModelPlace(
            id: e['id'] as int,
            tripId: e['tripId'] as int,
            placeOrder: e['placeOrder'] as int ?? 0,
            placeName: e['placeName'] as String,
            placeLatitude: e['placeLatitude'] as num,
            placeLongitude: e['placeLongitude'] as num,
            placeAddress: e['placeAddress'] as String,
            navigationUrl: e['navigationUrl'] as String,
          ),
        )
        .toList();
  }

  static Future<void> removePlace(int placeId) async {
    final database = await ServiceDB.getDatabase();
    await database.delete('place', where: 'id = ?', whereArgs: [placeId]);
  }

  static Future<void> updatePlaceOrder(List<ModelPlace> places) async {
    final database = await ServiceDB.getDatabase();
    debugPrint(
      'updatePlaceOrder service: ${places.map((e) => e.placeName).toList()}',
    );
    debugPrint(
      'updatePlaceOrder service: ${places.map((e) => e.placeOrder).toList()}',
    );
    for (int i = 0; i < places.length; i++) {
      await database.update(
        'place',
        {'placeOrder': i},
        where: 'id = ?',
        whereArgs: [places[i].id],
      );
    }
  }
}
