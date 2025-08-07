import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pj_trip/db/service_db.dart';
import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/components/map/map_google.dart';
import 'package:pj_trip/components/map/map_naver.dart';
import 'package:pj_trip/screens/screen_search.dart';
import 'package:pj_trip/components/ui/bot_sheet_single.dart';
import 'package:pj_trip/blocs/camera/camera_bloc.dart';
import 'package:pj_trip/blocs/location/location_bloc.dart';

import 'package:pj_trip/utils/camera_math.dart';
import 'package:pj_trip/utils/util.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pj_trip/store/current_travel/pods_current_travel.dart';

import 'package:pj_trip/db/model/model_place.dart';
import 'package:pj_trip/services/service_place.dart';
import 'package:pj_trip/components/ui/list/list_places.dart';

import 'package:pj_trip/components/map/map_naver_hook.dart';

import 'package:pj_trip/store/pods_camera.dart';

// 탭 내용을 위한 별도 위젯
class TripDayContent extends StatelessWidget {
  final Map<String, dynamic> trip;
  final List<Map<String, dynamic>> places;
  final Function(int)? onRemovePlace;

  const TripDayContent({
    super.key,
    required this.trip,
    required this.places,
    this.onRemovePlace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (places.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(place['placeName'] ?? ''),
                      subtitle: Text(place['tripId'].toString() ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onRemovePlace!(place['id']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '아직 방문할 장소가 없습니다',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '검색바를 눌러 장소를 추가해보세요!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ScreenMapHook extends HookConsumerWidget {
  const ScreenMapHook({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTravel = ref.watch(currentTravelProvider);
    final tabController = useTabController(
      initialLength: currentTravel.trips.length,
    );
    final camera = ref.watch(cameraProvider);
    final currentTabIndex = useState(0);
    final listPlacesByTripId = useState<List<ModelPlace>>([]);

    void navigateToSearch(int tripId) async {
      final result = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ScreenSearchHook(
                tripId: currentTravel.trips[currentTabIndex.value].id,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
          transitionDuration: Duration.zero,
        ),
      );

      if (result != null) {
        final targetLocation = result['targetLocation'];

        if (targetLocation != null) {
          if (context.mounted) {
            ref
                .read(cameraProvider.notifier)
                .setCameraLocation(
                  targetLocation.y,
                  targetLocation.x,

                  zoom: 10,
                );
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => BotSheetSingle(
                location: targetLocation,
                tripId: currentTravel.trips[currentTabIndex.value].id,
              ),
            );
          }
        }
      }
    }

    void onRemovePlace(int placeId) {
      ServicePlace.removePlace(placeId).then((_) {
        debugPrint('removePlace: $placeId');
        listPlacesByTripId.value = listPlacesByTripId.value
            .where((place) => place.id != placeId)
            .toList();
      });
    }

    useEffect(() {
      ServicePlace.getPlaces(
        currentTravel.trips[currentTabIndex.value].id,
      ).then((places) {
        listPlacesByTripId.value = places;
      });
      return null;
    }, [currentTabIndex.value]);

    return Scaffold(
      body: Stack(
        children: [
          // 배경 지도
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: currentTravel.isLocationKorea()
                      ? MapNaverHook()
                      : MapGoogle(),
                ),

                if (currentTravel.trips.isNotEmpty) ...[
                  Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 드래그 핸들
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // 탭바
                        SizedBox(
                          height: 50,
                          child: TabBar(
                            controller: tabController,
                            labelColor: Colors.blue,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.blue,
                            onTap: (index) => currentTabIndex.value = index,
                            tabs: currentTravel.trips.map((trip) {
                              return Tab(text: '${trip.tripOrder}일차');
                            }).toList(),
                          ),
                        ),
                        // 탭뷰
                        Expanded(
                          child: TabBarView(
                            controller: tabController,
                            children: currentTravel.trips.map((trip) {
                              return ListPlaces(
                                listPlaces: listPlacesByTripId.value,
                                onRemovePlace: onRemovePlace,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: const Center(child: Text('여행 정보가 없습니다')),
                  ),
                ],
              ],
            ),
          ),

          // 상단 검색바
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,

            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => navigateToSearch(
                        currentTravel.trips[currentTabIndex.value].id,
                      ),
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            // const SizedBox(width: 100),
                            Text(
                              '장소를 검색하세요',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScreenMap extends StatefulWidget {
  const ScreenMap({
    super.key,
    required this.isLocationKoreaProps,
    this.location,
    this.travel,
    this.trips,
  });

  final bool isLocationKoreaProps;
  final Location? location;
  final Map<String, dynamic>? travel;
  final List<Map<String, dynamic>>? trips;

  @override
  State<ScreenMap> createState() => _ScreenMapState();
}

class _ScreenMapState extends State<ScreenMap> with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabIndex = 0;
  var _places = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadInitialData();

    // 초기 위치 설정
    // final initialLocation =
    //     widget.location ??
    //     Location(
    //       title: '',
    //       address: '',
    //       x: widget.travel?['placeLongitude']?.toDouble() ?? 126.97829,
    //       y: widget.travel?['placeLatitude']?.toDouble() ?? 37.5666,
    //     );

    // context.read<LocationBloc>().selectLocation(initialLocation);
    // context.read<CameraBloc>().moveToLocation(initialLocation);
  }

  void _initializeTabController() {
    if (widget.trips == null || widget.trips!.isEmpty) {
      return;
    }

    try {
      _tabController = TabController(length: widget.trips!.length, vsync: this);

      _tabController!.addListener(_onTabChanged);
    } catch (e) {
      debugPrint('Failed to initialize TabController: $e');
      _tabController = null;
    }
  }

  // 안전한 tripId 가져오기
  int? _getCurrentTripId() {
    if (widget.trips == null ||
        _currentTabIndex < 0 ||
        _currentTabIndex >= widget.trips!.length) {
      return null;
    }

    try {
      return widget.trips![_currentTabIndex]['id'] as int;
    } catch (e) {
      debugPrint('Error getting trip ID: $e');
      return null;
    }
  }

  void _onTabChanged() {
    if (_tabController == null) return;

    final newIndex = _tabController!.index;

    // 인덱스 유효성 검사
    if (widget.trips == null ||
        newIndex < 0 ||
        newIndex >= widget.trips!.length) {
      return;
    }

    if (mounted) {
      setState(() {
        _currentTabIndex = newIndex;
      });
      _loadPlacesForCurrentTab();
    }
  }

  void _loadInitialData() {
    if (widget.trips != null && widget.trips!.isNotEmpty) {
      _loadPlacesForCurrentTab();
    } else {
      // trips가 없으면 travel 위치로 카메라 이동
      // _moveCameraToTravelLocation();
    }
  }

  void _moveCameraToTravelLocation() {
    if (widget.travel != null) {
      final travelLocation = Location(
        title: widget.travel!['placeName'] ?? 'Travel Location',
        address: widget.travel!['placeName'] ?? '',
        x: widget.travel!['placeLongitude']?.toDouble() ?? 126.97829,
        y: widget.travel!['placeLatitude']?.toDouble() ?? 37.5666,
      );

      if (mounted) {
        context.read<CameraBloc>().moveToLocation(travelLocation, zoom: 12.0);
      }

      debugPrint(
        'Initial: Moving camera to travel location: ${travelLocation.x}, ${travelLocation.y}',
      );
    }
  }

  void _loadPlacesForCurrentTab() {
    final tripId = _getCurrentTripId();
    if (tripId == null) {
      debugPrint('Cannot load places: invalid trip index $_currentTabIndex');
      return;
    }
    _getPlacesByTrip(tripId);
  }

  Future<void> _getPlacesByTrip(int tripId) async {
    if (tripId <= 0) return;
    try {
      final database = await ServiceDB.getDatabase();
      final places = await database.query(
        'place',
        where: 'tripId = ?',
        whereArgs: [tripId],
      );
      if (mounted) {
        if (!isListSame(places, _places)) {
          setState(() {
            _places = places;
          });
          // 탭 변경으로 인한 장소 목록 업데이트인 경우 카메라 이동
          if (_places.isNotEmpty) {
            _moveCameraToCurrentTabPlaces();
          } else {
            // 장소가 없으면 travel 좌표로 카메라 이동
            debugPrint(
              'No places found for trip $tripId, using travel coordinates',
            );
            // _moveCameraToTravelLocation();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading places for trip $tripId: $e');
      if (mounted) {
        setState(() {
          _places = [];
        });
        // 에러 발생 시에도 travel 좌표로 카메라 이동
        // _moveCameraToTravelLocation();
      }
    }
  }

  Future<void> _showLocationBottomSheet(Location location) async {
    final tripId = _getCurrentTripId();
    if (tripId == null) {
      debugPrint('Cannot show location bottom sheet: invalid trip data');
      return;
    }

    var result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BotSheetSingle(location: location, tripId: tripId),
    );

    // 바텀시트에서 장소가 추가/삭제되었을 수 있으므로 장소 목록 새로고침
    if (result != null) {
      _loadPlacesForCurrentTab();
    }
  }

  void _navigateToSearch() async {
    final tripId = _getCurrentTripId();
    if (tripId == null) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ScreenSearch(tripId: tripId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
      ),
    );

    // 검색 결과가 있으면 처리
    if (result != null && result is Map<String, dynamic>) {
      final locationData = result['location'];
      if (locationData != null) {
        // Location 객체를 Map으로 변환하여 전달받은 경우 처리
        Map<String, dynamic> locationMap;
        if (locationData is Location) {
          locationMap = {
            'title': locationData.title,
            'address': locationData.address,
            'x': locationData.x,
            'y': locationData.y,
          };
        } else if (locationData is Map<String, dynamic>) {
          locationMap = locationData;
        } else {
          debugPrint('Unknown location data type: ${locationData.runtimeType}');
          return;
        }

        // 여기서 선택된 위치 정보를 처리할 수 있습니다
        // 예: 지도에 마커 추가, 위치 정보 저장 등

        // 선택된 위치를 지도에 표시하기 위해 Location 객체 생성
        final selectedLocation = Location(
          title: locationMap['title'],
          address: locationMap['address'],
          x: locationMap['x'],
          y: locationMap['y'],
        );

        // LocationBloc에 선택된 위치 전달
        if (mounted) {
          context.read<LocationBloc>().selectLocation(selectedLocation);
          context.read<CameraBloc>().moveToLocation(selectedLocation, zoom: 14);
          _showLocationBottomSheet(selectedLocation);
        }
      }
    }

    debugPrint('Returned from ScreenSearch');
    // 장소 목록은 바텀시트에서 처리하므로 여기서는 새로고침하지 않음
  }

  void _moveCameraToCurrentTabPlaces() {
    if (_places.isNotEmpty) {
      // 현재 탭의 장소들의 중심점과 줌 계산
      final avgCenterLocation = getAvgCenterLocation(_places);
      final zoom = getZoomFromPlaces(_places);

      // BLoC을 통해 카메라 이동
      if (mounted) {
        context.read<CameraBloc>().moveToLocation(
          avgCenterLocation,
          zoom: zoom,
        );
      }

      debugPrint(
        'Tab changed: Moving camera to ${avgCenterLocation.x}, ${avgCenterLocation.y} places',
      );
    } else {
      // 장소가 없으면 travel 데이터를 사용하여 카메라 이동
      if (widget.travel != null) {
        debugPrint('widget.travel: ${widget.travel}');
        final travelLocation = Location(
          title: widget.travel!['placeName'] ?? 'Travel Location',
          address: widget.travel!['placeName'] ?? '',
          x: widget.travel!['placeLongitude']?.toDouble() ?? 126.97829,
          y: widget.travel!['placeLatitude']?.toDouble() ?? 37.5666,
        );

        if (mounted) {
          context.read<CameraBloc>().moveToLocation(travelLocation, zoom: 12.0);
        }

        debugPrint(
          'Tab changed: No places, moving camera to travel location: ${travelLocation.x}, ${travelLocation.y}',
        );
      } else {
        debugPrint('No travel data available for camera movement');
      }
    }
  }

  Future<void> _removePlaceFromTrip(int placeId) async {
    debugPrint('Removing place: $placeId');
    final database = await ServiceDB.getDatabase();
    await database.delete('place', where: 'id = ?', whereArgs: [placeId]);
    _loadPlacesForCurrentTab();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, locationState) {
        final selectedLocation = locationState is LocationLoaded
            ? locationState.selectedLocation
            : null;
        final isLocationKorea = locationState is LocationLoaded
            ? locationState.isLocationKorea
            : widget.isLocationKoreaProps;

        return Scaffold(
          body: Stack(
            children: [
              // 배경 지도
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: isLocationKorea
                          ? MapNaver(
                              location: selectedLocation,
                              places: _places,
                              key: ValueKey('map_naver_$_currentTabIndex'),
                            )
                          : const MapGoogle(),
                    ),

                    // 탭이 있는 바텀시트
                    if (widget.trips != null &&
                        widget.trips!.isNotEmpty &&
                        _tabController != null) ...[
                      Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            // 드래그 핸들
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // 탭바
                            SizedBox(
                              height: 50,
                              child: TabBar(
                                controller: _tabController!,
                                labelColor: Colors.blue,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: Colors.blue,
                                tabs: widget.trips!.map((trip) {
                                  return Tab(text: '${trip['tripOrder']}일차');
                                }).toList(),
                              ),
                            ),
                            // 탭뷰
                            Expanded(
                              child: TabBarView(
                                controller: _tabController!,
                                children: widget.trips!.map((trip) {
                                  return TripDayContent(
                                    trip: trip,
                                    places: _places,
                                    onRemovePlace: _removePlaceFromTrip,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        height: MediaQuery.of(context).size.height * 0.3,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: const Center(child: Text('여행 정보가 없습니다')),
                      ),
                    ],
                  ],
                ),
              ),

              // 상단 검색바
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,

                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _navigateToSearch,

                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                // const SizedBox(width: 100),
                                Text(
                                  selectedLocation != null
                                      ? selectedLocation.title
                                      : '장소를 검색하세요',
                                  style: TextStyle(
                                    color: selectedLocation != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
