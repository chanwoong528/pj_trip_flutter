import 'package:flutter/material.dart';
import 'package:pj_trip/db/service_db.dart';

import 'package:pj_trip/db/model/model_travel.dart';
import 'package:pj_trip/db/model/model_trip.dart';

class ServiceTravel {
  static Future<List<ModelTravel>> getTravelsWithTrips() async {
    try {
      final database = await ServiceDB.getDatabase();
      final travels = await database.query('travel');
      final travelsJson = travels
          .map(
            (e) => ModelTravel(
              id: e['id'] as int,
              travelName: e['travelName'] as String,
              placeName: e['placeName'] as String,
              placeLatitude: e['placeLatitude'] as num,
              placeLongitude: e['placeLongitude'] as num,
            ),
          )
          .toList();
      for (var travel in travelsJson) {
        final trips = await database.query(
          'trip',
          where: 'travelId = ?',
          whereArgs: [travel.id],
        );
        final tripsJson = trips
            .map(
              (e) => ModelTrip(
                id: e['id'] as int,
                travelId: e['travelId'] as int,
                tripName: e['tripName'] as String,
                tripOrder: e['tripOrder'] as int,
              ),
            )
            .toList();
        travel.setTrips(tripsJson);
      }

      for (var travel in travelsJson) {
        debugPrint('travel: ${travel.travelName} ${travel.id}');
        for (var trip in travel.trips) {
          debugPrint('trip: ${trip.tripName} ${trip.id}');
        }
      }
      return travelsJson;
      //   final travels = await database.rawQuery('''
      //   SELECT
      //     t.id,
      //     t.travelName,
      //     t.placeName,
      //     t.placeLatitude,
      //     t.placeLongitude,
      //     GROUP_CONCAT(
      //       tr.id || ',' || tr.tripOrder || ',' || tr.tripName || ',' ||
      //       COALESCE(
      //         (SELECT GROUP_CONCAT(p.id || ',' || p.placeOrder || ',' || p.placeName || ',' || p.placeLatitude || ',' || p.placeLongitude || ',' || p.placeAddress || ',' || p.navigationUrl, '^')
      //          FROM place p WHERE p.tripId = tr.id), ''
      //       ), '|'
      //     ) as trips
      //   FROM travel t
      //   LEFT JOIN trip tr ON t.id = tr.travelId
      //   GROUP BY t.id, t.travelName, t.placeName, t.placeLatitude, t.placeLongitude
      //   ORDER BY t.id DESC
      // ''');

      // [{id: 19, travelName: 한국, placeName: 대한민국, placeLatitude: 36.638392, placeLongitude: 127.6961188, trips: 175,1,한국 1일 여행|176,2,한국 2일 여행}, {id: 16, travelName: seoul, placeName: 서울특별시, placeLatitude: 37.5666791, placeLongitude: 126.9782914, trips: 166,1,seoul 1일 여행|167,2,seoul 2일 여행|168,3,seoul 3일 여행}, {id: 13, travelName: seoul, placeName: 서울특별시, placeLatitude: 37.5666791, placeLongitude: 126.9782914, trips: 157,1,seoul 1일 여행|158,2,seoul 2일 여행|159,3,seoul 3일 여행}]
    } catch (e) {
      debugPrint('ServiceTravel >getTravels error: $e');
      return [];
    }
  }
}
