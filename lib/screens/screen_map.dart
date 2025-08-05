import 'package:flutter/material.dart';
import 'package:pj_trip/db/service_db.dart';
import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/components/map/map_google.dart';
import 'package:pj_trip/components/map/map_naver.dart';
import 'package:pj_trip/screens/screen_search.dart';
import 'package:pj_trip/components/ui/bot_sheet_single.dart';

// 탭 내용을 위한 별도 위젯
class TripDayContent extends StatelessWidget {
  final Map<String, dynamic> trip;
  final List<Map<String, dynamic>> places;
  final VoidCallback? onRemovePlace;

  const TripDayContent({
    super.key,
    required this.trip,
    required this.places,
    this.onRemovePlace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${trip['tripOrder']}일차',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (places.isNotEmpty) ...[
            Text(
              '방문할 장소들:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  debugPrint(
                    'place@@@@@@@@@@ ########### : $place $index $places',
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(place['placeName'] ?? ''),
                      subtitle: Text(place['placeAddress'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onRemovePlace?.call(),
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

class ScreenMap extends StatefulWidget {
  const ScreenMap({
    super.key,
    required this.isLocationKorea,
    this.location,
    this.travel,
    this.trips,
  });

  final bool isLocationKorea;
  final Location? location;
  final Map<String, dynamic>? travel;
  final List<Map<String, dynamic>>? trips;

  @override
  State<ScreenMap> createState() => _ScreenMapState();
}

class _ScreenMapState extends State<ScreenMap> with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabIndex = 0;
  // 각 탭별로 장소를 캐시하는 Map
  final Map<int, List<Map<String, dynamic>>> _placesCache = {};
  var _places = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadInitialData();
  }

  void _initializeTabController() {
    if (widget.trips == null || widget.trips!.isEmpty) {
      debugPrint('No trips available for TabController');
      return;
    }

    try {
      _tabController = TabController(length: widget.trips!.length, vsync: this);

      _tabController!.addListener(_onTabChanged);
      debugPrint('TabController initialized with ${widget.trips!.length} tabs');
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
      debugPrint('Invalid tab index: $newIndex');
      return;
    }

    setState(() {
      _currentTabIndex = newIndex;
    });

    _loadPlacesForCurrentTab();
  }

  void _loadInitialData() {
    debugPrint(
      'Loading initial data - travel: ${widget.travel}, trips: ${widget.trips}',
    );

    if (widget.trips != null && widget.trips!.isNotEmpty) {
      _loadPlacesForCurrentTab();
    }
  }

  void _loadPlacesForCurrentTab() {
    final tripId = _getCurrentTripId();
    if (tripId == null) {
      debugPrint('Cannot load places: invalid trip index $_currentTabIndex');
      return;
    }

    // 캐시에 있으면 바로 사용
    if (_placesCache.containsKey(tripId)) {
      setState(() {
        _places = _placesCache[tripId]!;
      });
      debugPrint(
        'Using cached places for trip $tripId: ${_places.length} places',
      );
      return;
    }

    // 캐시에 없으면 로드
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

      debugPrint('Loaded ${places.length} places for trip $tripId');

      if (mounted) {
        // 캐시에 저장하고 현재 탭에 표시
        _placesCache[tripId] = places;
        setState(() {
          _places = places;
        });
      }
    } catch (e) {
      debugPrint('Error loading places for trip $tripId: $e');
      if (mounted) {
        _placesCache[tripId] = [];
        setState(() {
          _places = [];
        });
      }
    }
  }

  void _showLocationBottomSheet() {
    if (widget.location == null) {
      debugPrint('Cannot show location bottom sheet: no location');
      return;
    }

    final tripId = _getCurrentTripId();
    if (tripId == null) {
      debugPrint('Cannot show location bottom sheet: invalid trip data');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BotSheetSingle(location: widget.location!, tripId: tripId),
    );
  }

  void _navigateToSearch() {
    final tripId = _getCurrentTripId();
    if (tripId == null) {
      debugPrint('Cannot navigate to search: invalid trip data');
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ScreenSearch(tripId: tripId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
      ),
    ).then((_) {
      debugPrint('Returned from ScreenSearch, reloading places');
      // 캐시를 무효화하고 다시 로드
      _placesCache.remove(tripId);
      _loadPlacesForCurrentTab();
    });
  }

  Future<void> _removePlaceFromTrip(int placeId) async {
    debugPrint('Removing place: $placeId');
    // TODO: 장소 삭제 기능 구현
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 지도
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: widget.isLocationKorea
                      ? MapNaver(location: widget.location)
                      : const MapGoogle(),
                ),

                // 탭이 있는 바텀시트
                if (widget.trips != null &&
                    widget.trips!.isNotEmpty &&
                    _tabController != null) ...[
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6,
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
                                onRemovePlace: () => _removePlaceFromTrip(
                                  0,
                                ), // TODO: 실제 placeId 전달
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
                      onTap: _navigateToSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
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
