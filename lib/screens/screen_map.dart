import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:pj_trip/components/map/map_google.dart';

import 'package:pj_trip/screens/screen_search.dart';
import 'package:pj_trip/components/ui/bot_sheet_save_place.dart';
import 'package:pj_trip/components/ui/bot_sheet_searched_places.dart';

import 'package:pj_trip/services/service_search.dart';

import 'package:pj_trip/utils/camera_math.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pj_trip/store/current_travel/pods_current_travel.dart';

import 'package:pj_trip/services/service_place.dart';
import 'package:pj_trip/components/ui/list/list_places.dart';

import 'package:pj_trip/components/map/map_naver_hook.dart';
import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/store/pods_camera.dart';
import 'package:pj_trip/store/current_places/pods_current_places.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';

// 탭 내용을 위한 별도 위젯

class ScreenMapHook extends HookConsumerWidget {
  const ScreenMapHook({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTravel = ref.watch(currentTravelProvider);

    final tabController = useTabController(
      initialLength: currentTravel.trips.length,
    );
    final currentTabIndex = useState(0);
    final isExpanded = useState(false);

    final deletePlaceId = useState<int?>(null);

    void navigateToSearchedPlace(int tripId) async {
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
                  zoom: 12,
                );

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => BotSheetSavePlace(
                location: targetLocation,
                tripId: currentTravel.trips[currentTabIndex.value].id,
              ),
            );
          }
        }
      }
    }

    void onRemovePlace(int placeId) {
      debugPrint('onRemovePlace: $placeId');
      deletePlaceId.value = placeId;
      ServicePlace.removePlace(placeId).then((_) {
        ref.read(currentPlacesProvider.notifier).removeCurrentPlace(placeId);
      });
    }

    void onTapSinglePlace(SearchPlaceNaverResult place, int tripId) async {
      debugPrint('onTapSinglePlace: ${place.mapx}, ${place.mapy}');
      debugPrint('tripId: $tripId');

      // 위도 :
      // 129.1253433
      // 경도 :
      // 35.1568699
      final targetLocation = Location(
        x: place.mapx,
        y: place.mapy,
        title: place.title,
        address: place.address,
      );

      if (context.mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BotSheetSavePlace(
            location: targetLocation,
            tripId: currentTravel.trips[currentTabIndex.value].id,
          ),
        );
      }
    }

    void onTapMapGoogle(double lat, double lng) async {
      final searchedPlaces = await ServiceSearch().searchPlaceByLatLngGoogle(
        lat,
        lng,
      );
      if (context.mounted && searchedPlaces.isNotEmpty) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BotSheetSearchedPlaces(
            places: searchedPlaces,
            onTapSinglePlace: (place) => onTapSinglePlace(
              place,
              currentTravel.trips[currentTabIndex.value].id,
            ),
          ),
        );
      }
    }

    void onTapSymbolPlace(NSymbolInfo symbol) async {
      final searchedPlaces = await ServiceSearch().searchPlaceNaver(
        symbol.caption,
      );

      if (context.mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BotSheetSearchedPlaces(
            places: searchedPlaces,
            onTapSinglePlace: (place) => onTapSinglePlace(
              place,
              currentTravel.trips[currentTabIndex.value].id,
            ),
          ),
        );
      }
    }

    useEffect(() {
      ServicePlace.getPlaces(
        currentTravel.trips[currentTabIndex.value].id,
      ).then((places) {
        ref.read(currentPlacesProvider.notifier).setCurrentPlaces(places);
        if (places.isEmpty) {
          ref
              .read(cameraProvider.notifier)
              .setCameraLocation(0.0, 0.0, zoom: 11);
          return;
        }

        final avgCenterLocation = getAvgCenterLocationByPlacesModel(places);
        final zoom = getZoomFromPlacesByPlacesModel(places);

        ref
            .read(cameraProvider.notifier)
            .setCameraLocation(
              avgCenterLocation.y.toDouble(),
              avgCenterLocation.x.toDouble(),
              zoom: zoom,
            );
      });

      return null;
    }, [currentTabIndex.value, currentTravel.trips]);

    // tabController 리스너를 useEffect 밖으로 이동
    useEffect(() {
      tabController.addListener(
        () => currentTabIndex.value = tabController.index,
      );
      return null;
    }, [tabController]);

    return Scaffold(
      body: Stack(
        children: [
          // 배경 지도
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: currentTravel.isLocationKorea()
                      ? MapNaverHook(
                          deletePlaceId: deletePlaceId.value,
                          onTapSymbolPlace: onTapSymbolPlace,
                        )
                      : MapGoogleHook(
                          deletePlaceId: deletePlaceId.value,
                          onTapMapGoogle: onTapMapGoogle,
                        ),
                ),

                if (currentTravel.trips.isNotEmpty) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height:
                        MediaQuery.of(context).size.height *
                        (isExpanded.value ? 0.4 : 0.20),
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
                        GestureDetector(
                          onTap: () {
                            isExpanded.value = !isExpanded.value;
                          },
                          onVerticalDragStart: (details) {
                            // isExpanded.value = !isExpanded.value;
                          },
                          onVerticalDragUpdate: (details) {
                            // isExpanded.value = !isExpanded.value;
                          },
                          onVerticalDragEnd: (details) {
                            isExpanded.value = !isExpanded.value;
                          },

                          child: Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                              // color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: () {
                                isExpanded.value = !isExpanded.value;
                              },
                              child: isExpanded.value
                                  ? const Icon(
                                      Icons.expand_more,
                                      size: 30,
                                      color: Colors.grey,
                                    )
                                  : const Icon(
                                      Icons.expand_less,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                            ),
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
                            onTap: (index) => tabController.animateTo(index),
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
                              return ListPlaces(onRemovePlace: onRemovePlace);
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
                    onPressed: () =>
                        Navigator.popUntil(context, ModalRoute.withName('/')),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => navigateToSearchedPlace(
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
