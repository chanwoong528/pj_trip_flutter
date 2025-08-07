import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pods_camera.g.dart';

class CameraModel {
  double lat;
  double lng;
  double zoom;

  CameraModel({required this.lat, required this.lng, this.zoom = 10});
}

@riverpod
class Camera extends _$Camera {
  @override
  CameraModel build() => CameraModel(lat: 0, lng: 0);

  void setCameraLocation(double lat, double lng, {double? zoom}) {
    state = CameraModel(lat: lat, lng: lng, zoom: zoom ?? state.zoom);
  }

  void setZoom(double zoom) {
    state = CameraModel(lat: state.lat, lng: state.lng, zoom: zoom);
  }
}
