import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:pj_trip/components/ui/marker_icon.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:pj_trip/services/service_search.dart';
import 'package:pj_trip/store/pods_camera.dart';
import 'package:pj_trip/store/current_travel/pods_current_travel.dart';
import 'package:pj_trip/store/pods_searched_marker.dart';
import 'package:pj_trip/store/current_places/pods_current_places.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:pj_trip/db/model/model_place.dart';

class MapGoogleHook extends HookConsumerWidget {
  const MapGoogleHook({
    super.key,
    this.initialCamera,
    this.deletePlaceId,
    this.onTapMapGoogle,
  });
  final CameraModel? initialCamera;
  final int? deletePlaceId;
  final Function(double, double)? onTapMapGoogle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = useRef<google_maps.GoogleMapController?>(null);
    final curMarker = ref.watch(markerProvider);
    final camera = ref.watch(cameraProvider);
    final currentTravel = ref.watch(currentTravelProvider);
    final currentPlaces = ref.watch(currentPlacesProvider);
    final markers = useState<Set<google_maps.Marker>>({});
    final polylines = useState<Set<google_maps.Polyline>>({});

    google_maps.LatLng calculateCameraPosition() {
      // Priority 1: Use initialCamera if provided and valid
      if (initialCamera != null &&
          initialCamera!.lat != 0 &&
          initialCamera!.lat != -1 &&
          initialCamera!.lng != 0 &&
          initialCamera!.lng != -1) {
        // lat = longitude, lng = latitude, but LatLng expects (latitude, longitude)
        final result = google_maps.LatLng(
          initialCamera!.lng, // latitude
          initialCamera!.lat, // longitude
        );

        return result;
      }

      // Priority 2: Use camera provider if valid
      if (camera.lat != 0 &&
          camera.lat != -1 &&
          camera.lng != 0 &&
          camera.lng != -1) {
        final result = google_maps.LatLng(
          camera.lng, // latitude
          camera.lat, // longitude
        );

        return result;
      }

      // Priority 3: Use current travel location if valid
      if (currentTravel.placeLatitude != 0 &&
          currentTravel.placeLongitude != 0) {
        // placeLatitude = latitude, placeLongitude = longitude
        final result = google_maps.LatLng(
          currentTravel.placeLatitude.toDouble(),
          currentTravel.placeLongitude.toDouble(),
        );

        return result;
      }

      final result = const google_maps.LatLng(37.5665, 126.9780);

      return result;
    }

    void onMapCreated(google_maps.GoogleMapController controller) =>
        mapController.value = controller;

    void moveCamera(google_maps.LatLng latLng, double zoom) async {
      try {
        if (mapController.value != null) {
          debugPrint(
            'Moving camera to: ${latLng.latitude}, ${latLng.longitude}, zoom: $zoom',
          );
          await mapController.value!.animateCamera(
            google_maps.CameraUpdate.newCameraPosition(
              google_maps.CameraPosition(target: latLng, zoom: zoom),
            ),
          );
        }
      } catch (e) {
        debugPrint('moveCamera error: $e');
      }
    }

    void deleteMarker(int? placeId) {
      if (placeId == null) return;

      markers.value = {...markers.value}
        ..removeWhere(
          (marker) => marker.markerId.value == "trip_place_$placeId",
        );
    }

    Future<void> addMarkers(List<ModelPlace> places) async {
      final newMarkers = <google_maps.Marker>{};

      for (final (index, place) in places.indexed) {
        final marker = google_maps.Marker(
          markerId: google_maps.MarkerId('trip_place_${place.id}'),
          position: google_maps.LatLng(
            place.placeLongitude.toDouble(),
            place.placeLatitude.toDouble(),
          ),
          icon: await MarkerIcon(number: index + 1).toBitmapDescriptor(),
          infoWindow: google_maps.InfoWindow(title: place.placeName),
        );
        newMarkers.add(marker);
      }

      markers.value = {...newMarkers};
    }

    void addMarker(google_maps.Marker marker) async {
      markers.value = {...markers.value, marker};
      await Future.delayed(const Duration(milliseconds: 100));
      markers.value = {...markers.value, marker};
    }

    void searchPlaceByLatLngGoogle(double lat, double lng) {
      if (onTapMapGoogle != null) {
        onTapMapGoogle!(lat, lng);
        return;
      }
      ServiceSearch().searchPlaceByLatLngGoogle(lat, lng);
    }

    // Only move camera when map controller is available and camera changes
    useEffect(() {
      if (mapController.value != null &&
          camera.lat != 0 &&
          camera.lat != -1 &&
          camera.lng != 0 &&
          camera.lng != -1) {
        moveCamera(google_maps.LatLng(camera.lng, camera.lat), camera.zoom);
      }
      return null;
    }, [camera.lat, camera.lng, camera.zoom]);

    useEffect(
      () {
        polylines.value = {};

        Future.microtask(() async {
          await addMarkers(currentPlaces);
        });

        final polyline = google_maps.Polyline(
          polylineId: google_maps.PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: currentPlaces
              .map(
                (e) => google_maps.LatLng(
                  e.placeLongitude.toDouble(),
                  e.placeLatitude.toDouble(),
                ),
              )
              .toList(),
        );

        if (currentPlaces.isNotEmpty) {
          polylines.value = {polyline};
        } else {
          polylines.value = {};
        }

        // debugPrint('polylines:>>> ${polylines.value}');
        return null;
      },
      [
        currentPlaces.map((e) => e.placeOrder).toList().toString(),
        currentPlaces.map((e) => e.id).toList().toString(),
      ],
    ); // placeOrder 대신 length만 사용하여 불필요한 재실행 방지

    useEffect(() {
      if (mapController.value != null) {
        deleteMarker(deletePlaceId);
      }
      return null;
    }, [deletePlaceId, mapController.value]);

    // Move camera when marker changes
    useEffect(() {
      if (mapController.value != null &&
          curMarker.markerId.isNotEmpty &&
          curMarker.lat != 0 &&
          curMarker.lat != -1 &&
          curMarker.lng != 0 &&
          curMarker.lng != -1) {
        moveCamera(
          google_maps.LatLng(curMarker.lng, curMarker.lat),
          camera.zoom,
        );
        addMarker(
          google_maps.Marker(
            markerId: google_maps.MarkerId(curMarker.markerId),
            position: google_maps.LatLng(curMarker.lng, curMarker.lat),
            infoWindow: google_maps.InfoWindow(title: curMarker.title),
            icon: google_maps.BitmapDescriptor.defaultMarkerWithHue(
              google_maps.BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
      return null;
    }, [curMarker.lat, curMarker.lng, curMarker.title]);

    final initialPosition = calculateCameraPosition();
    final initialZoom = initialCamera?.zoom ?? camera.zoom;

    return Scaffold(
      body: google_maps.GoogleMap(
        mapType: google_maps.MapType.normal,
        initialCameraPosition: google_maps.CameraPosition(
          target: initialPosition,
          zoom: initialZoom,
        ),
        markers: markers.value,
        polylines: polylines.value,
        onMapCreated: onMapCreated,
        onLongPress: (latLng) =>
            searchPlaceByLatLngGoogle(latLng.latitude, latLng.longitude),
        myLocationButtonEnabled: false,
      ),
    );
  }
}
