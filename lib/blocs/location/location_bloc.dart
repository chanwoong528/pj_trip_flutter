import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pj_trip/domain/location.dart';

// Events
abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LocationSelected extends LocationEvent {
  final Location location;

  const LocationSelected(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationCleared extends LocationEvent {}

class LocationUpdated extends LocationEvent {
  final Location location;

  const LocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

// States
abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoaded extends LocationState {
  final Location? selectedLocation;
  final bool isLocationKorea;

  const LocationLoaded({this.selectedLocation, this.isLocationKorea = false});

  @override
  List<Object?> get props => [selectedLocation, isLocationKorea];

  LocationLoaded copyWith({Location? selectedLocation, bool? isLocationKorea}) {
    return LocationLoaded(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      isLocationKorea: isLocationKorea ?? this.isLocationKorea,
    );
  }
}

// BLoC
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationInitial()) {
    on<LocationSelected>(_onLocationSelected);
    on<LocationCleared>(_onLocationCleared);
    on<LocationUpdated>(_onLocationUpdated);
  }

  void _onLocationSelected(
    LocationSelected event,
    Emitter<LocationState> emit,
  ) {
    emit(
      LocationLoaded(
        selectedLocation: event.location,
        isLocationKorea: _isLocationKorea(event.location),
      ),
    );
  }

  void _onLocationCleared(LocationCleared event, Emitter<LocationState> emit) {
    emit(const LocationLoaded(selectedLocation: null));
  }

  void _onLocationUpdated(LocationUpdated event, Emitter<LocationState> emit) {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      emit(currentState.copyWith(selectedLocation: event.location));
    } else {
      emit(
        LocationLoaded(
          selectedLocation: event.location,
          isLocationKorea: _isLocationKorea(event.location),
        ),
      );
    }
  }

  bool _isLocationKorea(Location location) {
    return location.y > 33 &&
        location.y < 38.5 &&
        location.x > 124 &&
        location.x < 132;
  }
}

// 편의를 위한 확장 메서드
extension LocationBlocExtension on LocationBloc {
  void selectLocation(Location location) {
    add(LocationSelected(location));
  }

  void clearLocation() {
    add(LocationCleared());
  }

  void updateLocation(Location location) {
    add(LocationUpdated(location));
  }
}
