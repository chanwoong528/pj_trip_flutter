import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pj_trip/db/model/model_place.dart';

class ListPlaces extends HookConsumerWidget {
  const ListPlaces({
    super.key,
    required this.listPlaces,
    required this.onRemovePlace,
  });

  final List<ModelPlace> listPlaces;
  final Function(int) onRemovePlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (listPlaces.isEmpty) {
      return const Center(child: Text('장소가 없습니다'));
    }

    return ListView.builder(
      itemCount: listPlaces.length,
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      itemBuilder: (context, index) {
        final place = listPlaces[index];

        return Card.outlined(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(place.placeName),
            subtitle: Text(place.tripId.toString()),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onRemovePlace(place.id),
            ),
          ),
        );
      },
    );
  }
}
