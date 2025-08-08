import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:pj_trip/services/service_search.dart';

class BotSheetSearchedPlaces extends HookConsumerWidget {
  const BotSheetSearchedPlaces({super.key, required this.places});
  final List<SearchPlaceNaverResult> places;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (places.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
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
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '검색 결과',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: places.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(places[index].title),
                        subtitle: Text(places[index].address ?? ''),
                        onTap: () {
                          // TODO: 장소 선택 처리
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
