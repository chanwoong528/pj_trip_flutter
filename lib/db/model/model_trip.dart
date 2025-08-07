import 'package:pj_trip/db/model/model_place.dart';

class ModelTrip {
  final int id;
  final int travelId;
  final String tripName;
  final num tripOrder;
  List<ModelPlace> places;

  ModelTrip({
    required this.id,
    required this.travelId,
    required this.tripName,
    required this.tripOrder,
    this.places = const [],
  });

  ModelTrip copyWith({
    int? id,
    int? travelId,
    String? tripName,
    num? tripOrder,
    List<ModelPlace>? places,
  }) {
    return ModelTrip(
      id: id ?? this.id,
      travelId: travelId ?? this.travelId,
      tripName: tripName ?? this.tripName,
      tripOrder: tripOrder ?? this.tripOrder,
      places: places ?? this.places,
    );
  }

  void addPlace(ModelPlace place) {
    places = [...places, place];
  }

  void setPlaces(List<ModelPlace> places) {
    this.places = places;
  }
}
