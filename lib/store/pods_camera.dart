import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

part 'pods_camera.g.dart';

class CameraModel {
  double lat;
  double lng;
  double zoom;

  CameraModel({required this.lat, required this.lng, this.zoom = 11});
}

@riverpod
class Camera extends _$Camera {
  @override
  CameraModel build() => CameraModel(lat: 0, lng: 0);

  void setCameraLocation(double lat, double lng, {double? zoom}) {
    final newZoom = zoom ?? state.zoom;

    // Only update if the values have actually changed
    if (state.lat == lat && state.lng == lng && state.zoom == newZoom) {
      debugPrint('Camera location unchanged, skipping update');
      return;
    }

    debugPrint('=== setCameraLocation called ===');
    debugPrint('Previous state: ${state.lat}, ${state.lng}, ${state.zoom}');
    debugPrint('New values: $lat, $lng, zoom: $newZoom');

    state = CameraModel(lat: lat, lng: lng, zoom: newZoom);

    debugPrint('State updated to: ${state.lat}, ${state.lng}, ${state.zoom}');
    debugPrint('=== setCameraLocation completed ===');
  }

  void setZoom(double zoom) {
    state = CameraModel(lat: state.lat, lng: state.lng, zoom: zoom);
  }
}
