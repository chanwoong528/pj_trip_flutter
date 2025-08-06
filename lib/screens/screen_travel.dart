import 'package:flutter/material.dart';
import 'package:pj_trip/db/service_db.dart';
import 'package:pj_trip/services/service_search.dart';
import 'package:pj_trip/domain/location.dart';

import 'package:pj_trip/components/map/map_google.dart';
import 'package:pj_trip/components/map/map_naver.dart';
import 'package:pj_trip/screens/screen_map.dart';
import 'dart:async';

class ScreenTravel extends StatefulWidget {
  const ScreenTravel({super.key});

  @override
  State<ScreenTravel> createState() => _ScreenTravelState();
}

class _ScreenTravelState extends State<ScreenTravel> {
  Map<String, dynamic>? travel;
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _travelNameController = TextEditingController();

  final ServiceSearch _serviceSearch = ServiceSearch();
  Timer? _debounceTimer;
  var _searchResults = <Location>[];

  var _targetLocation = Location(address: '', title: '', x: 0, y: 0);
  var _isLoading = false;

  bool _isLocationInKorea(Location location) {
    // 주소에 한국 관련 키워드가 있는지 확인
    final koreanKeywords = ['한국', '대한민국', 'Korea', 'South Korea', 'KR'];
    final address = location.address.toLowerCase();
    return koreanKeywords.any(
      (keyword) => address.contains(keyword.toLowerCase()),
    );
  }

  @override
  void initState() {
    super.initState();
    // 네비게이션 arguments에서 데이터 받기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        setState(() {
          travel = args as Map<String, dynamic>;
          _travelNameController.text = travel!['englishName'];
        });
        debugPrint('Received travel name: $travel');
      }
    });
  }

  @override
  void dispose() {
    _daysController.dispose();
    _travelNameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchPlace(String query) async {
    // 이전 타이머가 있다면 취소
    _debounceTimer?.cancel();

    // 1초 딜레이 후 검색 실행 (API 제한 방지)
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      if (query.isNotEmpty) {
        final results = await _serviceSearch.searchPlaceNominatim(query);
        debugPrint('검색 결과 개수: ${results.length}');
        setState(() {
          _searchResults = results;
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _addTravelToDB() async {
    if (_travelNameController.text.isEmpty || _daysController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('여행 이름과 일수를 입력해주세요')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final database = await ServiceDB.getDatabase();

      // travel 테이블에 데이터 삽입
      final travelId = await database.insert('travel', {
        'travelName': _travelNameController.text,
        'placeName': _targetLocation.title,
        'placeLatitude': _targetLocation.y,
        'placeLongitude': _targetLocation.x,
      });

      // trip 테이블에 데이터 삽입
      final batch = database.batch();
      for (int i = 0; i < int.parse(_daysController.text); i++) {
        batch.insert('trip', {
          'travelId': travelId,
          'tripName': '${_travelNameController.text} ${i + 1}일 여행',
          'tripOrder': i + 1,
        });
      }
      await batch.commit();

      setState(() {
        _isLoading = false;
      });
      final travel = await database.query(
        'travel',
        where: 'id = ?',
        whereArgs: [travelId],
      );
      final trips = await database.query(
        'trip',
        where: 'travelId = ?',
        whereArgs: [travelId],
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenMap(
              isLocationKoreaProps: _isLocationInKorea(_targetLocation),
              travel: travel.isNotEmpty ? travel.first : null,
              trips: trips,
            ),
          ),
        );
        debugPrint('travel: $travel');
        debugPrint('trips: $trips');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('여행이 성공적으로 추가되었습니다!')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
      debugPrint('DB 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  controller: _travelNameController,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Where to go?',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => _searchPlace(value),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              width: 40,
              child: IconButton(
                onPressed: _addTravelToDB,
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
          if (_searchResults.isNotEmpty) ...[
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
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
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
                    onTap: () {
                      _targetLocation = item;
                      setState(() {
                        _searchResults = [];
                      });
                      debugPrint('선택된 장소: ${item.title}');
                    },
                  );
                },
              ),
            ),
          ],
          // 선택된 위치가 있으면 지도와 여행 정보 표시
          if (_targetLocation.title.isNotEmpty) ...[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _isLocationInKorea(_targetLocation)
                    ? MapNaver(location: _targetLocation)
                    : MapGoogle(),
              ),
            ),
            // 바텀시트로 여행 정보 표시
            if (_targetLocation.title.isNotEmpty)
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
                      _targetLocation.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _targetLocation.address,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    // 여행 일수 입력
                    TextField(
                      controller: _daysController,
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
                        onPressed: _isLoading ? null : _addTravelToDB,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
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
  }
}
