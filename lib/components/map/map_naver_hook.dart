import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:pj_trip/store/pods_camera.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pj_trip/store/pods_searched_marker.dart';
import 'package:pj_trip/store/current_places/pods_current_places.dart';
import 'package:pj_trip/db/model/model_place.dart';

import 'package:pj_trip/store/current_travel/pods_current_travel.dart';
import 'package:pj_trip/components/ui/marker_icon.dart';

class MapNaverHook extends HookConsumerWidget {
  const MapNaverHook({
    super.key,
    this.deletePlaceId,
    this.initialCamera,
    this.onTapSymbolPlace,
  });
  final int? deletePlaceId;
  final CameraModel? initialCamera;
  final Function(NSymbolInfo)? onTapSymbolPlace;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapControllerRef = useState<NaverMapController?>(null);

    final camera = ref.watch(cameraProvider);
    final curMarker = ref.watch(markerProvider);
    final currentPlaces = ref.watch(currentPlacesProvider);
    final currentTravel = ref.watch(currentTravelProvider);

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

    Future<void> markPlaces(List<ModelPlace> places) async {
      try {
        if (mapControllerRef.value == null || places.isEmpty) return;

        final markers = <NMarker>{};

        for (final (index, place) in places.indexed) {
          final iconImage = await NOverlayImage.fromWidget(
            widget: MarkerIcon(number: index + 1),
            size: const Size(24, 24),
            context: context,
          );
          markers.add(
            NMarker(
              id: 'trip_place_${place.id}',
              position: NLatLng(
                place.placeLatitude.toDouble(),
                place.placeLongitude.toDouble(),
              ),
              icon: iconImage,
            ),
          );
        }
        final path = makePath(places);
        mapControllerRef.value?.addOverlayAll({...markers, path});
      } catch (e) {
        debugPrint('Failed to mark places: $e');
      }
    }

    NLatLng caculateCameraPosition() {
      if (initialCamera != null &&
          initialCamera!.lat != -1 &&
          initialCamera!.lng != -1 &&
          initialCamera!.lat != 0 &&
          initialCamera!.lng != 0) {
        return NLatLng(initialCamera!.lng, initialCamera!.lat);
      }
      if (camera.lat != -1 &&
          camera.lng != -1 &&
          camera.lat != 0 &&
          camera.lng != 0) {
        //TODO: have to set the standard on lat lng

        return NLatLng(camera.lat, camera.lng);
      }

      if (currentPlaces.isNotEmpty) {
        return NLatLng(
          currentPlaces.first.placeLatitude.toDouble(),
          currentPlaces.first.placeLongitude.toDouble(),
        );
      }

      return NLatLng(
        currentTravel.placeLatitude.toDouble(),
        currentTravel.placeLongitude.toDouble(),
      );
    }

    void deletePlaceMarker(int? placeId) {
      try {
        if (mapControllerRef.value == null || placeId == null) return;

        mapControllerRef.value?.deleteOverlay(
          NOverlayInfo(id: 'trip_place_$placeId', type: NOverlayType.marker),
        );
      } catch (e) {
        debugPrint('Failed to delete marker for place $placeId: $e');
      }
    }

    void onSymbolTapped(NSymbolInfo symbol) async {
      if (onTapSymbolPlace != null) {
        onTapSymbolPlace!(symbol);
        return;
      }
    }

    useEffect(
      () {
        if (mapControllerRef.value != null) {
          mapControllerRef.value?.updateCamera(
            NCameraUpdate.withParams(
              target: caculateCameraPosition(),
              zoom: camera.zoom,
            ),
          );
        }

        if (currentPlaces.isNotEmpty) {
          Future.microtask(() async {
            await markPlaces(currentPlaces);
          });
        }

        return null;
      },
      [
        camera.lat,
        camera.lng,
        camera.zoom,
        currentPlaces.map((e) => e.id).toList(),
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
            target: caculateCameraPosition(),
            zoom: initialCamera?.zoom ?? camera.zoom,
          ),
        ),
        onMapReady: (controller) => mapControllerRef.value = controller,
        onSymbolTapped: (symbol) => onSymbolTapped(symbol),
      ),
    );
  }
}
