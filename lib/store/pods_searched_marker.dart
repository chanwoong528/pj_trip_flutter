import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pods_searched_marker.g.dart';

class MarkerModel {
  double lat;
  double lng;
  String markerId;
  String title;
  MarkerModel({
    required this.lat,
    required this.lng,
    required this.markerId,
    required this.title,
  });
}

@riverpod
class Marker extends _$Marker {
  @override
  MarkerModel build() => MarkerModel(lat: 0, lng: 0, markerId: '', title: '');

  void setMarkerLocation(
    double lat,
    double lng,
    String markerId,
    String title,
  ) {
    state = MarkerModel(lat: lat, lng: lng, markerId: markerId, title: title);
  }
}
