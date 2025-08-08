import 'package:flutter/material.dart';
import 'package:pj_trip/db/model/model_place.dart';
import 'package:pj_trip/db/service_db.dart';
import 'package:pj_trip/domain/location.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pj_trip/store/current_places/pods_current_places.dart';

class BotSheetSavePlace extends HookConsumerWidget {
  const BotSheetSavePlace({
    super.key,
    required this.location,
    required this.tripId,
  });

  final Location location;
  final int tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> addPlaceToTrip(int tripId, Location place) async {
      final database = await ServiceDB.getDatabase();
      final places = await database.query(
        'place',
        where: 'tripId = ?',
        whereArgs: [tripId],
      );
      final placeOrder = places.length + 1;

      final id = await database.insert('place', {
        'tripId': tripId,
        'placeOrder': placeOrder,
        'placeName': place.title,
        'placeLatitude': place.y,
        'placeLongitude': place.x,
        'placeAddress': place.address,
        'navigationUrl': 'place_url_${place.title}',
      });

      ref
          .read(currentPlacesProvider.notifier)
          .addCurrentPlace(
            ModelPlace(
              id: id,
              tripId: tripId,
              placeOrder: placeOrder,
              placeName: place.title,
              placeLatitude: place.y,
              placeLongitude: place.x,
              placeAddress: place.address,
              navigationUrl: 'place_url_${place.title}',
            ),
          );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 장소 정보
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  location.address,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${location.x.toStringAsFixed(6)}, ${location.y.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // 길찾기 기능
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('길찾기'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      addPlaceToTrip(tripId, location);
                      Navigator.pop(context, {
                        'isLocationKorea': true,
                        'location': location,
                      });
                    },
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('저장'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BotSheetSingle extends StatelessWidget {
  const BotSheetSingle({
    super.key,
    required this.location,
    required this.tripId,
  });

  final Location location;
  final int tripId;

  Future<void> _addPlaceToTrip(int tripId, Location place) async {
    final database = await ServiceDB.getDatabase();
    final places = await database.query(
      'place',
      where: 'tripId = ?',
      whereArgs: [tripId],
    );
    final placeOrder = places.length + 1;

    await database.insert('place', {
      'tripId': tripId,
      'placeOrder': placeOrder,
      'placeName': place.title,
      'placeLatitude': place.y,
      'placeLongitude': place.x,
      'placeAddress': place.address,
      'navigationUrl': 'place_url_${place.title}',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 장소 정보
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  location.address,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${location.x.toStringAsFixed(6)}, ${location.y.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // 길찾기 기능
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('길찾기'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _addPlaceToTrip(tripId, location);
                      Navigator.pop(context, {
                        'isLocationKorea': true,
                        'location': location,
                      });
                    },
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('저장'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
