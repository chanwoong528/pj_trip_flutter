import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:pj_trip/store/pods_camera.dart';
import 'package:pj_trip/store/current_travel/pods_current_travel.dart';
import 'package:pj_trip/store/pods_searched_marker.dart';
import 'package:pj_trip/store/current_places/pods_current_places.dart';
import 'package:pj_trip/db/model/model_place.dart';

class MapGoogleHook extends HookConsumerWidget {
  const MapGoogleHook({super.key, this.initialCamera, this.deletePlaceId});
  final CameraModel? initialCamera;
  final int? deletePlaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = useRef<google_maps.GoogleMapController?>(null);
    final curMarker = ref.watch(markerProvider);
    final camera = ref.watch(cameraProvider);
    final currentTravel = ref.watch(currentTravelProvider);
    final currentPlaces = ref.watch(currentPlacesProvider);
    final markers = useState<Set<google_maps.Marker>>({});

    google_maps.LatLng calculateCameraPosition() {
      debugPrint('=== calculateCameraPosition called ===');
      debugPrint('initialCamera: ${initialCamera?.lat}, ${initialCamera?.lng}');
      debugPrint('camera provider: ${camera.lat}, ${camera.lng}');
      debugPrint(
        'currentTravel: ${currentTravel.placeLatitude}, ${currentTravel.placeLongitude}',
      );

      // Priority 1: Use initialCamera if provided and valid
      if (initialCamera != null &&
          initialCamera!.lat != 0 &&
          initialCamera!.lat != -1 &&
          initialCamera!.lng != 0 &&
          initialCamera!.lng != -1) {
        debugPrint(
          'Using initialCamera: ${initialCamera!.lat}, ${initialCamera!.lng}',
        );
        // lat = longitude, lng = latitude, but LatLng expects (latitude, longitude)
        final result = google_maps.LatLng(
          initialCamera!.lng, // latitude
          initialCamera!.lat, // longitude
        );
        debugPrint('Returning LatLng: ${result.latitude}, ${result.longitude}');
        return result;
      }

      // Priority 2: Use camera provider if valid
      if (camera.lat != 0 &&
          camera.lat != -1 &&
          camera.lng != 0 &&
          camera.lng != -1) {
        debugPrint('Using camera provider: ${camera.lat}, ${camera.lng}');
        // lat = longitude, lng = latitude, but LatLng expects (latitude, longitude)
        final result = google_maps.LatLng(
          camera.lng, // latitude
          camera.lat, // longitude
        );
        debugPrint('Returning LatLng: ${result.latitude}, ${result.longitude}');
        return result;
      }

      // Priority 3: Use current travel location if valid
      if (currentTravel.placeLatitude != 0 &&
          currentTravel.placeLongitude != 0) {
        debugPrint(
          'Using travel location: ${currentTravel.placeLatitude}, ${currentTravel.placeLongitude}',
        );
        // placeLatitude = latitude, placeLongitude = longitude
        final result = google_maps.LatLng(
          currentTravel.placeLatitude.toDouble(),
          currentTravel.placeLongitude.toDouble(),
        );
        debugPrint('Returning LatLng: ${result.latitude}, ${result.longitude}');
        return result;
      }

      // Fallback: Default to Seoul
      debugPrint('Using default location: Seoul');
      final result = const google_maps.LatLng(37.5665, 126.9780);
      debugPrint('Returning LatLng: ${result.latitude}, ${result.longitude}');
      debugPrint('=== calculateCameraPosition completed ===');
      return result;
    }

    void onMapCreated(google_maps.GoogleMapController controller) {
      mapController.value = controller;
      debugPrint('Google Map created');
    }

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

    void addMarker(google_maps.Marker marker) {
      markers.value = {...markers.value, marker};
    }

    void deleteMarker(int? placeId) {
      if (placeId == null) return;

      debugPrint('Deleting marker: $placeId');
      markers.value = {...markers.value}
        ..removeWhere(
          (marker) => marker.markerId.value == "trip_place_$placeId",
        );

      debugPrint('Markers: ${markers.value.map((e) => e.infoWindow.title)}');
      debugPrint('Markers: ${markers.value.map((e) => e.markerId)}');
    }

    // Only move camera when map controller is available and camera changes
    useEffect(
      () {
        if (mapController.value != null &&
            camera.lat != 0 &&
            camera.lat != -1 &&
            camera.lng != 0 &&
            camera.lng != -1) {
          debugPrint('Camera changed, moving to: ${camera.lat}, ${camera.lng}');
          // lat = longitude, lng = latitude, but LatLng expects (latitude, longitude)
          moveCamera(google_maps.LatLng(camera.lng, camera.lat), camera.zoom);
        }
        if (currentPlaces.isNotEmpty) {
          debugPrint('Adding ${currentPlaces.length} markers');
          for (final place in currentPlaces) {
            addMarker(
              google_maps.Marker(
                markerId: google_maps.MarkerId('trip_place_${place.id}'),
                position: google_maps.LatLng(
                  place.placeLongitude.toDouble(),
                  place.placeLatitude.toDouble(),
                ),
                icon: google_maps.BitmapDescriptor.defaultMarkerWithHue(
                  google_maps.BitmapDescriptor.hueBlue,
                ),
                infoWindow: google_maps.InfoWindow(title: place.placeName),
              ),
            );
          }
        }
        return null;
      },
      [
        camera.lat,
        camera.lng,
        camera.zoom,
        currentPlaces.map((e) => e.placeOrder).toList(),
      ],
    );

    useEffect(() {
      debugPrint('deletePlaceId: $deletePlaceId');
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
        debugPrint(
          'Marker changed, moving to: ${curMarker.lat}, ${curMarker.lng}',
        );
        // lat = longitude, lng = latitude, but LatLng expects (latitude, longitude)
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
        initialCameraPosition: google_maps.CameraPosition(
          target: initialPosition,
          zoom: initialZoom,
        ),
        onMapCreated: onMapCreated,
        markers: markers.value,
      ),
    );
  }
}

// class MapGoogle extends StatefulWidget {
//   const MapGoogle({super.key});

//   @override
//   State<MapGoogle> createState() => _MapGoogleState();
// }

// class _MapGoogleState extends State<MapGoogle> {
//   final Completer<GoogleMapController> _controller =
//       Completer<GoogleMapController>();

//   static const CameraPosition _kGooglePlex = CameraPosition(
//     target: LatLng(37.4537251, 126.7960716),
//     zoom: 1,
//   );

//   static const CameraPosition _kLake = CameraPosition(
//     bearing: 192.8334901395799,
//     target: LatLng(37.43296265331129, -122.08832357078792),
//     tilt: 59.440717697143555,
//     zoom: 10,
//   );
//   final Set<Polyline> _polylines = {};
//   final List<Marker> _markers = [];

//   @override
//   void initState() {
//     super.initState();

//     for (var i = 0; i < 10; i++) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId("${i + 1}"),
//           draggable: true,
//           onTap: () => print("Marker!"),
//           position: LatLng(37.4537251 + i, 126.7960716 + i),
//         ),
//       );
//     }
//     _updatePolyline();
//   }

//   void _updatePolyline() {
//     final polyline = Polyline(
//       polylineId: PolylineId('route'),
//       color: Colors.blue,
//       width: 5,
//       points: _markers.map((m) => m.position).toList(),
//     );
//     setState(() {
//       _polylines.clear();
//       _polylines.add(polyline);
//     });
//   }

//   void _updatePosition(CameraPosition position) {
//     var m = _markers.firstWhere(
//       (p) => p.markerId == MarkerId('1'),
//       orElse: () => Marker(
//         markerId: MarkerId('1'),
//         position: LatLng(0, 0),
//         draggable: true,
//       ),
//     );
//     _markers.remove(m);
//     _markers.add(
//       Marker(
//         markerId: MarkerId('1'),
//         position: LatLng(position.target.latitude, position.target.longitude),
//         draggable: true,
//       ),
//     );
//     _updatePolyline();
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Map')),
//       body: GoogleMap(
//         mapType: MapType.normal,
//         markers: Set.from(_markers),
//         polylines: _polylines,
//         initialCameraPosition: _kGooglePlex,
//         onCameraMove: ((position) => _updatePosition(position)),
//         onTap: (LatLng latLng) {
//           debugPrint('onTap@map_google : $latLng');
//         },
//         onMapCreated: (GoogleMapController controller) {
//           _controller.complete(controller);
//         },
//       ),
//       // floatingActionButton: FloatingActionButton.extended(
//       //   onPressed: _goToTheLake,
//       //   label: const Text('To the lake!'),
//       //   icon: const Icon(Icons.directions_boat),
//       // ),
//     );
//   }

//   // Future<void> _goToTheLake() async {
//   //   final GoogleMapController controller = await _controller.future;
//   //   await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
//   // }
// }
