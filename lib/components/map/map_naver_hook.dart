import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pj_trip/store/pods_camera.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pj_trip/store/pods_searched_marker.dart';
import 'package:pj_trip/store/current_places/pods_current_places.dart';
import 'package:pj_trip/db/model/model_place.dart';

class MapNaverHook extends HookConsumerWidget {
  const MapNaverHook({super.key});

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
      if (mapControllerRef.value == null || places.isEmpty) return;

      // mapControllerRef.value?.clearOverlays(); //TODO: consider if it's needed
      final markers = <NMarker>{};
      for (final place in places) {
        markers.add(
          NMarker(
            id: place.id.toString(),
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
        currentPlaces.length,
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
    final safeAreaPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      body: NaverMap(
        options: NaverMapViewOptions(
          contentPadding: safeAreaPadding,
          tiltGesturesEnable: false,
          rotationGesturesEnable: false,
          scrollGesturesFriction: 0.1,
        ),
        onMapReady: (controller) {
          mapControllerRef.value = controller;
          debugPrint('Map controller ready');
        },
      ),
    );
  }
}
