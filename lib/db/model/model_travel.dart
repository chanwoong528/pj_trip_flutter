import 'package:pj_trip/db/model/model_place.dart';
import 'package:pj_trip/db/model/model_trip.dart';

class ModelTravel {
  final int id;
  final String travelName;
  final String placeName;
  final num placeLatitude;
  final num placeLongitude;
  final Bounds? bounds;
  List<ModelTrip> trips;

  ModelTravel({
    required this.id,
    required this.travelName,
    required this.placeName,
    required this.placeLatitude,
    required this.placeLongitude,
    this.bounds,
    this.trips = const [],
  });
  void setTrips(List<ModelTrip> trips) {
    this.trips = trips;
  }

  bool isLocationKorea() {
    return placeLatitude > 33 &&
        placeLatitude < 38.5 &&
        placeLongitude > 124 &&
        placeLongitude < 132;
  }
}
