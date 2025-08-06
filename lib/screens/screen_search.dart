import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/services/service_search.dart';
import 'package:pj_trip/blocs/location/location_bloc.dart';

class ScreenSearch extends StatefulWidget {
  const ScreenSearch({super.key, required this.tripId});

  final int tripId;

  @override
  State<ScreenSearch> createState() => _ScreenSearchState();
}

class _ScreenSearchState extends State<ScreenSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ServiceSearch _serviceSearch = ServiceSearch();

  List<Location> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 화면이 마운트되면 자동으로 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final results = await _serviceSearch.searchPlaceKakao(
          _searchController.text,
        );
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('검색 오류: $e');
      }
    }
  }

  // Future<void> addPlaceToTrip(int tripId, Location place) async {
  //   final database = await ServiceDB.getDatabase();
  //   await database.insert('place', {
  //     'tripId': tripId,
  //     'placeName': place.title,
  //     'placeLatitude': place.y,
  //     'placeLongitude': place.x,
  //   });
  // }

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
                  controller: _searchController,
                  focusNode: _focusNode,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: InputDecoration(
                    hintText: '장소를 검색하세요',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    search();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              width: 40,
              child: IconButton(
                onPressed: search,
                icon: const Icon(Icons.search),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '검색 결과가 여기에 표시됩니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.address ?? '주소 없음',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.add_location, size: 16),
                    onTap: () {
                      debugPrint('선택된 장소: ${item.title}');

                      // LocationBloc에 선택된 위치 전달
                      context.read<LocationBloc>().selectLocation(item);

                      Navigator.pop(context, {
                        'isLocationKorea': true,
                        'location': item,
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
