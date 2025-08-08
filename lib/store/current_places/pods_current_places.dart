import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pj_trip/db/model/model_place.dart';

part 'pods_current_places.g.dart';

@riverpod
class CurrentPlaces extends _$CurrentPlaces {
  @override
  List<ModelPlace> build() => [];

  void setCurrentPlaces(List<ModelPlace> places) {
    state = places;
  }

  void addCurrentPlace(ModelPlace place) {
    state = [...state, place];
  }

  void addCurrentPlaceByIndex(int index, ModelPlace place) {
    state = [...state.sublist(0, index), place, ...state.sublist(index)];
  }

  void removeCurrentPlace(int placeId) {
    state = state.where((place) => place.id != placeId).toList();
  }

  void removeCurrentPlaceByIndex(int index) {
    state = state.where((place) => place.id != state[index].id).toList();
  }
}
