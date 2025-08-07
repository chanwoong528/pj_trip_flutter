import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pj_trip/db/model/model_travel.dart';
import 'package:pj_trip/db/model/model_trip.dart';
import 'package:pj_trip/db/model/model_place.dart';

part 'pods_current_travel.g.dart';

@riverpod
class CurrentTravel extends _$CurrentTravel {
  //client side data  to check which is selected travel
  @override
  ModelTravel build() => ModelTravel(
    id: 0,
    travelName: '',
    placeName: '',
    placeLatitude: 0,
    placeLongitude: 0,
    trips: [],
  );

  void setCurrentTravel(ModelTravel travel) {
    state = travel;
  }

  void addTripToCurrentTravel(ModelTrip trip) {
    state = ModelTravel(
      id: state.id,
      travelName: state.travelName,
      placeName: state.placeName,
      placeLatitude: state.placeLatitude,
      placeLongitude: state.placeLongitude,
      trips: [...state.trips, trip],
    );
  }

  void removeTripFromCurrentTravel(int tripId) {
    state = ModelTravel(
      id: state.id,
      travelName: state.travelName,
      placeName: state.placeName,
      placeLatitude: state.placeLatitude,
      placeLongitude: state.placeLongitude,
      trips: state.trips.where((t) => t.id != tripId).toList(),
    );
  }

  void addPlaceToCurrentTravelOnTrip(int tripId, ModelPlace place) {
    state = ModelTravel(
      id: state.id,
      travelName: state.travelName,
      placeName: state.placeName,
      placeLatitude: state.placeLatitude,
      placeLongitude: state.placeLongitude,
      trips: state.trips
          .map(
            (t) =>
                t.id == tripId ? t.copyWith(places: [...t.places, place]) : t,
          )
          .toList(),
    );
  }

  void removePlaceFromCurrentTravelOnTrip(int tripId, int placeId) {
    state = ModelTravel(
      id: state.id,
      travelName: state.travelName,
      placeName: state.placeName,
      placeLatitude: state.placeLatitude,
      placeLongitude: state.placeLongitude,
      trips: state.trips
          .map(
            (t) => t.id == tripId
                ? t.copyWith(
                    places: t.places.where((p) => p.id != placeId).toList(),
                  )
                : t,
          )
          .toList(),
    );
  }
}
