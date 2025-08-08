import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pj_trip/store/pods_camera.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pj_trip/store/pods_searched_marker.dart';
import 'package:pj_trip/store/current_places/pods_current_places.dart';
import 'package:pj_trip/db/model/model_place.dart';
import 'package:pj_trip/services/service_search.dart';
import 'package:pj_trip/components/ui/bot_sheet_searched_places.dart';

class MapNaverHook extends HookConsumerWidget {
  const MapNaverHook({super.key, this.deletePlaceId});
  final int? deletePlaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapControllerRef = useState<NaverMapController?>(null);

    final camera = ref.watch(cameraProvider);
    final curMarker = ref.watch(markerProvider);
    final currentPlaces = ref.watch(currentPlacesProvider);

    NMultipartPathOverlay makePath(List<ModelPlace> places) {
      if (mapControllerRef.value == null || places.isEmpty) {
        return NMultipartPathOverlay(
          id: "test",
          paths: [
            NMultipartPath(
              coords: [],
              color: Colors.red,
              outlineColor: Colors.red,
              passedColor: Colors.red,
              passedOutlineColor: Colors.red,
            ),
          ],
        );
      }
      final coords = <NLatLng>[];
      for (final place in places) {
        coords.add(
          NLatLng(
            place.placeLatitude.toDouble(),
            place.placeLongitude.toDouble(),
          ),
        );
      }
      final path = NMultipartPath(
        coords: coords,
        color: Colors.red,
        outlineColor: Colors.red,
        passedColor: Colors.red,
        passedOutlineColor: Colors.red,
      );

      return NMultipartPathOverlay(id: "test", paths: [path]);
    }

    void markPlaces(List<ModelPlace> places) {
      try {
        if (mapControllerRef.value == null || places.isEmpty) return;

        final markers = <NMarker>{};
        for (final place in places) {
          markers.add(
            NMarker(
              id: 'trip_place_${place.id}',
              iconTintColor: Colors.blue,
              position: NLatLng(
                place.placeLatitude.toDouble(),
                place.placeLongitude.toDouble(),
              ),
            ),
          );
        }
        final path = makePath(places);
        mapControllerRef.value?.addOverlayAll({...markers, path});
      } catch (e) {
        debugPrint('Failed to mark places: $e');
      }
    }

    void deletePlaceMarker(int? placeId) {
      try {
        if (mapControllerRef.value == null || placeId == null) return;

        mapControllerRef.value?.deleteOverlay(
          NOverlayInfo(id: 'trip_place_${placeId}', type: NOverlayType.marker),
        );
      } catch (e) {
        debugPrint('Failed to delete marker for place $placeId: $e');
      }
    }

    void onSymbolTapped(NSymbolInfo symbol) async {
      final searchedPlaces = await ServiceSearch().searchPlaceNaver(
        symbol.caption,
      );

      if (context.mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BotSheetSearchedPlaces(places: searchedPlaces),
        );
      }
    }

    useEffect(
      () {
        if (mapControllerRef.value != null) {
          debugPrint(mapControllerRef.value?.getLocationOverlay().toString());

          mapControllerRef.value?.updateCamera(
            NCameraUpdate.withParams(
              target: NLatLng(camera.lat, camera.lng),
              zoom: camera.zoom,
            ),
          );
        }

        if (currentPlaces.isNotEmpty) {
          markPlaces(currentPlaces);
        }

        return null;
      },
      [
        camera.lat,
        camera.lng,
        camera.zoom,
        currentPlaces.map((e) => e.placeOrder).toList(),
        mapControllerRef.value,
      ],
    );

    useEffect(() {
      if (curMarker.markerId.isNotEmpty) {
        mapControllerRef.value?.deleteOverlay(
          NOverlayInfo(id: 'searched_marker', type: NOverlayType.marker),
        );
        mapControllerRef.value?.addOverlay(
          NMarker(
            id: 'searched_marker',
            position: NLatLng(curMarker.lat, curMarker.lng),
            caption: NOverlayCaption(text: curMarker.title),
          ),
        );
      }
      return null;
    }, [curMarker.lat, curMarker.lng, curMarker.title]);

    useEffect(() {
      debugPrint('deletePlaceId: $deletePlaceId');
      if (mapControllerRef.value != null) {
        deletePlaceMarker(deletePlaceId);
      }
      return null;
    }, [deletePlaceId, mapControllerRef.value]);

    final safeAreaPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      body: NaverMap(
        options: NaverMapViewOptions(
          contentPadding: safeAreaPadding,
          tiltGesturesEnable: false,
          rotationGesturesEnable: false,
          scrollGesturesFriction: 0.1,
          initialCameraPosition: NCameraPosition(
            target: NLatLng(camera.lat, camera.lng),
            zoom: camera.zoom,
          ),
        ),
        onMapReady: (controller) {
          mapControllerRef.value = controller;
          debugPrint('Map controller ready');
        },

        onSymbolTapped: (symbol) => onSymbolTapped(symbol),
      ),
    );
  }
}
