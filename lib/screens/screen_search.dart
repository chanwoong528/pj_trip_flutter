import 'package:flutter/material.dart';

import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/services/service_search.dart';
import 'package:pj_trip/store/pods_searched_marker.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ScreenSearchHook extends HookConsumerWidget {
  const ScreenSearchHook({super.key, this.tripId = -1});

  final int tripId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('tripId: $tripId');

    final ServiceSearch serviceSearch = ServiceSearch();
    final searchController = useTextEditingController();

    final focusNode = useFocusNode();
    final searchResults = useState<List<Location>>([]);
    final isLoading = useState<bool>(false);

    Future<void> search() async {
      if (searchController.text.isEmpty) return;
      isLoading.value = true;
      try {
        final results = await serviceSearch.searchPlaceKakao(
          searchController.text,
        );
        searchResults.value = results;
        isLoading.value = false;
      } catch (e) {
        isLoading.value = false;
        debugPrint('검색 오류: $e');
      }
    }

    void onTapSearchedPlace(Location place) {
      debugPrint('선택된 장소: ${place.title}');
      ref
          .read(markerProvider.notifier)
          .setMarkerLocation(
            place.y.toDouble(),
            place.x.toDouble(),
            'searched_marker',
            place.title,
          );
      Navigator.pop(context, {
        'isLocationKorea': true,
        'targetLocation': place,
      });
    }

    useEffect(() {
      focusNode.requestFocus();
      return null;
    }, []);

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
                  controller: searchController,
                  focusNode: focusNode,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: InputDecoration(
                    hintText: '장소를 검색하세요',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) => search(),
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
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : searchResults.value.isEmpty
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
              itemCount: searchResults.value.length,
              itemBuilder: (context, index) {
                final item = searchResults.value[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.address,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.add_location, size: 16),
                    onTap: () => onTapSearchedPlace(item),
                  ),
                );
              },
            ),
    );
  }
}
