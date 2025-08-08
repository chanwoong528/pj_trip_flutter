import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:pj_trip/services/service_place.dart';
import 'package:pj_trip/store/current_places/pods_current_places.dart';

class ListPlaces extends HookConsumerWidget {
  const ListPlaces({
    super.key,
    // required this.listPlaces,
    required this.onRemovePlace,
  });

  final Function(int) onRemovePlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.primary.withValues(alpha: 0.05);
    final Color evenItemColor = colorScheme.primary.withValues(alpha: 0.15);
    final currentPlaces = ref.watch(currentPlacesProvider);

    if (currentPlaces.isEmpty) {
      return const Center(child: Text('장소가 없습니다'));
    }

    useEffect(() {
      final tempList = currentPlaces
          .asMap()
          .entries
          .map((entry) => entry.value.copyWith(placeOrder: entry.key))
          .toList();

      ServicePlace.updatePlaceOrder(tempList).then((_) {});
      return null;
    }, [currentPlaces]);
    void onReorder(int oldIndex, int newIndex) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      ref
          .read(currentPlacesProvider.notifier)
          .removeCurrentPlaceByIndex(oldIndex);
      ref
          .read(currentPlacesProvider.notifier)
          .addCurrentPlaceByIndex(newIndex, currentPlaces[oldIndex]);
    }

    return ReorderableListView(
      children: <Widget>[
        for (int index = 0; index < currentPlaces.length; index++)
          ColoredBox(
            key: Key('$index'),
            color: index.isOdd ? oddItemColor : evenItemColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(8),

                      child: ReorderableDragStartListener(
                        index: index,
                        child: Card(
                          color: colorScheme.primary,
                          elevation: 2,
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ),
                    Text('Item ${currentPlaces[index].placeName}'),
                  ],
                ),
                IconButton(
                  onPressed: () => onRemovePlace(currentPlaces[index].id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ),
      ],
      onReorder: (int oldIndex, int newIndex) => onReorder(oldIndex, newIndex),
    );

    // return ListView.builder(
    //   itemCount: orderList.value.length,
    //   padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
    //   itemBuilder: (context, index) {
    //     final place = orderList.value[index];

    //     return Card.outlined(
    //       margin: const EdgeInsets.only(bottom: 8),
    //       child: ListTile(
    //         leading: const Icon(Icons.location_on),
    //         title: Text(place.placeName),
    //         subtitle: Text(place.tripId.toString()),
    //         trailing: IconButton(
    //           icon: const Icon(Icons.delete, color: Colors.red),
    //           onPressed: () => onRemovePlace(place.id),
    //         ),
    //       ),
    //     );
    //   },
    // );
  }
}
