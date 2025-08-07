import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pj_trip/components/ui/home_carousel.dart';
import 'package:pj_trip/db/model/model_travel.dart';
import 'package:pj_trip/db/service_db.dart';
import 'package:pj_trip/screens/screen_map.dart';
import 'package:pj_trip/blocs/camera/camera_bloc.dart';
import 'package:pj_trip/blocs/location/location_bloc.dart';
import 'package:pj_trip/domain/location.dart';

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

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  List<Map<String, dynamic>> _travels = [];

  Future<void> _loadData() async {
    final database = await ServiceDB.getDatabase();

    // 각 travel에 해당하는 trip들을 그룹화
    final travels = await database.rawQuery('''
      SELECT 
        t.id,
        t.travelName,
        t.placeName,
        t.placeLatitude,
        t.placeLongitude,
        GROUP_CONCAT(tr.id || ',' || tr.tripOrder || ',' || tr.tripName, '|') as trips
      FROM travel t
      LEFT JOIN trip tr ON t.id = tr.travelId
      GROUP BY t.id, t.travelName, t.placeName, t.placeLatitude, t.placeLongitude
      ORDER BY t.id DESC
    ''');

    if (mounted) {
      setState(() {
        _travels = travels
            .map((travel) => travel as Map<String, dynamic>)
            .toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    _loadData();
  }

  // void _navigateToMap() {
  //   Navigator.pushNamed(context, '/map');
  // }

  // void _navigateToNaverMap() {
  //   Navigator.pushNamed(context, '/map');
  // }

  Future<void> _navigateToMap(Map<String, dynamic> travel) async {
    // trips 문자열을 파싱하여 List<Map<String, dynamic>>으로 변환
    final tripsString = travel['trips'] as String?;
    List<Map<String, dynamic>> trips = [];

    if (tripsString != null && tripsString.isNotEmpty) {
      final tripStrings = tripsString.split('|');
      trips = tripStrings.map((tripString) {
        final parts = tripString.split(',');
        return {
          'id': int.parse(parts[0]),
          'tripOrder': int.parse(parts[1]),
          'tripName': parts[2],
          'travelId': travel['id'],
        };
      }).toList();
    }

    // debugPrint('trips: ${trips[0]}');

    // Travel 좌표로 카메라 이동
    if (travel['placeLatitude'] != null && travel['placeLongitude'] != null) {
      final travelLocation = Location(
        title: travel['placeName'] ?? 'Travel Location',
        address: travel['placeName'] ?? '',
        x: travel['placeLongitude'].toDouble(),
        y: travel['placeLatitude'].toDouble(),
      );

      // BLoC을 통해 카메라 이동
      context.read<CameraBloc>().moveToLocation(travelLocation, zoom: 12.0);
      context.read<LocationBloc>().selectLocation(travelLocation);

      debugPrint(
        'Home: Moving camera to travel location: ${travelLocation.x}, ${travelLocation.y}',
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ScreenMap(travel: travel, trips: trips, isLocationKoreaProps: true),
      ),
    );
  }

  void addTravel() {
    Navigator.pushNamed(context, '/travel').then((_) {
      _loadData();
    });
  }

  Future<void> _deleteTravel(Map<String, dynamic> travel) async {
    try {
      final database = await ServiceDB.getDatabase();

      // 먼저 관련된 place들을 삭제
      final trips = await database.query(
        'trip',
        where: 'travelId = ?',
        whereArgs: [travel['id']],
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
        whereArgs: [travel['id']],
      );

      // travel 삭제
      await database.delete(
        'travel',
        where: 'id = ?',
        whereArgs: [travel['id']],
      );

      // UI 업데이트
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${travel['travelName']} 여행이 삭제되었습니다.'),
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

  void _shareTravel(Map<String, dynamic> travel) async {
    final trips = travel['trips'];

    final tripCount = trips.length;

    final message = '여행 정보를 공유합니다.\n\n일정: $tripCount일';
    final encodedMessage = Uri.encodeComponent(message);
    final url =
        'https://www.google.com/maps/dir/?api=1&travelmode=driving&waypoints=$encodedMessage';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          HomeCarousel(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _travels.length,
              itemBuilder: (context, index) {
                final travel = _travels[index];
                final tripsString = travel['trips'] as String?;
                final tripCount = tripsString?.split('|').length ?? 0;

                return Slidable(
                  key: ValueKey(travel['id']),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _deleteTravel(travel),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: '삭제',
                      ),
                      SlidableAction(
                        onPressed: (_) => _shareTravel(travel),
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
                        travel['travelName'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${travel['placeName'] ?? ''} -일정 $tripCount일',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      onTap: () => _navigateToMap(travel),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 카메라 제어 버튼들
          FloatingActionButton(
            heroTag: 'add',
            onPressed: addTravel,
            tooltip: 'Add Travel',
            child: const Icon(Icons.add),
          ),
          // FloatingActionButton(
          //   heroTag: 'delete data',
          //   onPressed: () async {
          //     final database = await ServiceDB.getDatabase();
          //     await database.delete('travel');
          //     await database.delete('trip');
          //     await database.delete('place');
          //     _loadData();
          //   },
          //   tooltip: 'Delete Data',
          //   child: const Icon(Icons.delete),
          // ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
