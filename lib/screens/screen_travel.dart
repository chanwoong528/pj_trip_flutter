import 'package:flutter/material.dart';
import 'package:pj_trip/components/map/map_naver_hook.dart';
import 'package:pj_trip/db/service_db.dart';
import 'package:pj_trip/services/service_search.dart';
import 'package:pj_trip/domain/location.dart';

import 'package:pj_trip/components/map/map_google.dart';

import 'package:pj_trip/screens/screen_map.dart';
import 'package:pj_trip/store/pods_camera.dart';
import 'dart:async';

import 'package:pj_trip/utils/camera_math.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:pj_trip/store/pods_searched_marker.dart';
import 'package:pj_trip/store/current_travel/pods_current_travel.dart';
import 'package:pj_trip/db/model/model_travel.dart';
import 'package:pj_trip/db/model/model_trip.dart';

class ScreenTravelHook extends HookConsumerWidget {
  const ScreenTravelHook({super.key, this.travelName});

  final String? travelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceSearch = ServiceSearch();

    final travelNameController = useTextEditingController();
    final daysController = useTextEditingController();

    final searchResults = useState<List<Location>>([]);

    final targetLocation = useState<Location>(
      Location(address: '', title: '', x: 126.9780, y: 37.5665),
    );
    final isLoading = useState<bool>(false);
    final debounceTimer = useRef<Timer?>(null);

    Future<void> searchPlace(String query) async {
      // 이전 타이머가 있다면 취소
      if (query.isEmpty) return;

      debounceTimer.value?.cancel();
      // 1초 딜레이 후 검색 실행 (API 제한 방지)
      debounceTimer.value = Timer(const Duration(milliseconds: 1000), () async {
        if (query.isNotEmpty) {
          final results = await serviceSearch.searchPlaceNominatim(query);
          debugPrint('검색 결과 개수: ${results.length}');
          searchResults.value = results;
        } else {
          searchResults.value = [];
        }
      });
    }

    void onTapSearchedCity(Location place) {
      targetLocation.value = place;
      searchResults.value = [];

      debugPrint('선택된 장소: ${place.x} ${place.y} ${place.title}');
      ref
          .read(markerProvider.notifier)
          .setMarkerLocation(
            place.y.toDouble(),
            place.x.toDouble(),
            'searched_marker',
            place.title,
          );

      ref
          .read(cameraProvider.notifier)
          .setCameraLocation(place.y.toDouble(), place.x.toDouble());
    }

    Future<void> addTravelToDB() async {
      if (travelNameController.text.isEmpty || daysController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('여행 이름과 일수를 입력해주세요')));
        return;
      }

      isLoading.value = true;
      try {
        final database = await ServiceDB.getDatabase();

        final travelId = await database.insert('travel', {
          'travelName': travelNameController.text,
          'placeName': targetLocation.value.title,
          'placeLatitude': targetLocation.value.y,
          'placeLongitude': targetLocation.value.x,
        });

        final batch = database.batch();
        for (int i = 0; i < int.parse(daysController.text); i++) {
          batch.insert('trip', {
            'travelId': travelId,
            'tripName': '${travelNameController.text} ${i + 1}일 여행',
            'tripOrder': i + 1,
          });
        }
        await batch.commit();

        final trips = await database.query(
          'trip',
          where: 'travelId = ?',
          whereArgs: [travelId],
        );

        final targetTravel = ModelTravel(
          id: travelId,
          travelName: travelNameController.text,
          placeName: targetLocation.value.title,
          placeLatitude: targetLocation.value.y,
          placeLongitude: targetLocation.value.x,
          trips: trips
              .map(
                (e) => ModelTrip(
                  id: e['id'] as int,
                  travelId: e['travelId'] as int,
                  tripName: e['tripName'] as String,
                  tripOrder: e['tripOrder'] as num,
                ),
              )
              .toList(),
        );
        ref.read(currentTravelProvider.notifier).setCurrentTravel(targetTravel);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ScreenMapHook()),
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('여행이 성공적으로 추가되었습니다!')));
        }
      } catch (e) {
        debugPrint('DB 오류: $e');
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      travelNameController.text = travelName ?? '';
      searchPlace(travelNameController.text);
      return null;
    }, [travelName]);

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey, height: 1),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(color: Colors.white),
                child: TextField(
                  controller: travelNameController,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Where to go?',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => searchPlace(value),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              width: 40,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.save),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색 결과 드롭다운
          if (searchResults.value.isNotEmpty) ...[
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: searchResults.value.length,
                itemBuilder: (context, index) {
                  final item = searchResults.value[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Icon(Icons.location_on),
                    title: Text(
                      item.title.isNotEmpty ? item.title : '이름 없음',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      item.address.isNotEmpty ? item.address : '주소 없음',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onTapSearchedCity(item),
                  );
                },
              ),
            ),
          ],
          // 선택된 위치가 있으면 지도와 여행 정보 표시
          if (targetLocation.value.title.isNotEmpty) ...[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: isLocationInKorea(targetLocation.value)
                    ? MapNaverHook()
                    : MapGoogle(),
              ),
            ),
            // 바텀시트로 여행 정보 표시
            if (targetLocation.value.title.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 드래그 핸들
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 위치 정보
                    Text(
                      targetLocation.value.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      targetLocation.value.address,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    // 여행 일수 입력
                    TextField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '여행 일수',
                        hintText: '몇 일 동안 여행하시나요?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 여행 추가 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading.value ? null : addTravelToDB,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                '여행 추가하기',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            // 선택된 위치가 없을 때 기본 메시지
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '위치를 검색하여 선택해주세요',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
    ;
  }
}
