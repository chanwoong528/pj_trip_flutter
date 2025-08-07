import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:pj_trip/components/ui/home_carousel.dart';
import 'package:pj_trip/db/model/model_travel.dart';
import 'package:pj_trip/db/service_db.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:pj_trip/services/service_travel.dart';

import 'package:pj_trip/store/current_travel/pods_current_travel.dart';

class ScreenHomeHook extends HookConsumerWidget {
  const ScreenHomeHook({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelsState = useState<List<ModelTravel>>([]);
    final currentTravel = ref.watch(currentTravelProvider);

    Future<void> deleteTravel(ModelTravel travel) async {
      try {
        final database = await ServiceDB.getDatabase();

        // 먼저 관련된 place들을 삭제
        final trips = await database.query(
          'trip',
          where: 'travelId = ?',
          whereArgs: [travel.id],
        );

        for (final trip in trips) {
          await database.delete(
            'place',
            where: 'tripId = ?',
            whereArgs: [trip['id']],
          );
        }

        // trip들을 삭제
        await database.delete(
          'trip',
          where: 'travelId = ?',
          whereArgs: [travel.id],
        );

        // travel 삭제
        await database.delete(
          'travel',
          where: 'id = ?',
          whereArgs: [travel.id],
        );

        travelsState.value = travelsState.value
            .where((t) => t.id != travel.id)
            .toList();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${travel.travelName} 여행이 삭제되었습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        debugPrint('Error deleting travel: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('삭제 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    void shareTravel(ModelTravel travel) async {
      final trips = travel.trips;

      final tripCount = trips.length;

      final message = '여행 정보를 공유합니다.\n\n일정: $tripCount일';
      final encodedMessage = Uri.encodeComponent(message);
      final url =
          'https://www.google.com/maps/dir/?api=1&travelmode=driving&waypoints=$encodedMessage';
    }

    Future<void> navigateToMap(ModelTravel travel) async {
      ref.read(currentTravelProvider.notifier).setCurrentTravel(travel);
      Navigator.pushNamed(context, '/map');
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ScreenMap(
      //       travel: travel,
      //       trips: trips,
      //       isLocationKoreaProps: true,
      //     ),
      //   ),
      // );
      //TODO: 카메라 이동 코드 추가
      //TODO: map 화면으로 이동
    }

    useEffect(() {
      ServiceTravel.getTravelsWithTrips().then((travels) {
        travelsState.value = travels;
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentTravel.travelName == ''
              ? 'Home'
              : "${currentTravel.travelName} - ${currentTravel.trips.length}일",
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          HomeCarousel(),
          const SizedBox(height: 20),
          Text('Travels: ${travelsState.value.length}'),
          Expanded(
            child: ListView.builder(
              itemCount: travelsState.value.length,
              itemBuilder: (context, index) {
                final travel = travelsState.value[index];
                final tripCount = travel.trips.length;

                return Slidable(
                  key: ValueKey(travel.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => deleteTravel(travel),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: '삭제',
                      ),
                      SlidableAction(
                        onPressed: (_) => shareTravel(travel),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.share,
                        label: '공유',
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      title: Text(
                        travel.travelName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${travel.placeName} -일정 $tripCount일',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      onTap: () => navigateToMap(travel),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
