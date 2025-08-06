import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pj_trip/domain/location.dart';

// 편의를 위한 확장 메서드
extension CameraBlocExtension on CameraBloc {
  void moveTo(double latitude, double longitude, {double? zoom}) {
    add(CameraMoveToCoordinates(latitude, longitude, zoom: zoom));
  }

  void moveToLocation(Location location, {double? zoom}) {
    add(CameraMoveToLocation(location, zoom: zoom));
  }

  void reset() {
    add(CameraReset());
  }
}

// Events
abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

class CameraMoveToLocation extends CameraEvent {
  final Location location;
  final double? zoom;

  const CameraMoveToLocation(this.location, {this.zoom});

  @override
  List<Object?> get props => [location, zoom];
}

class CameraMoveToCoordinates extends CameraEvent {
  final double latitude;
  final double longitude;
  final double? zoom;

  const CameraMoveToCoordinates(this.latitude, this.longitude, {this.zoom});

  @override
  List<Object?> get props => [latitude, longitude, zoom];
}

class CameraReset extends CameraEvent {}

// States
abstract class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => [];
}

class CameraInitial extends CameraState {}

class CameraPosition extends CameraState {
  final Location location;
  final double zoom;

  const CameraPosition({required this.location, required this.zoom});

  @override
  List<Object?> get props => [location, zoom];

  CameraPosition copyWith({Location? location, double? zoom}) {
    return CameraPosition(
      location: location ?? this.location,
      zoom: zoom ?? this.zoom,
    );
  }
}

// BLoC
class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraBloc() : super(CameraInitial()) {
    on<CameraMoveToLocation>(_onCameraMoveToLocation);
    on<CameraMoveToCoordinates>(_onCameraMoveToCoordinates);
    on<CameraReset>(_onCameraReset);
  }

  void _onCameraMoveToLocation(
    CameraMoveToLocation event,
    Emitter<CameraState> emit,
  ) {
    debugPrint(
      'CameraMoveToLocation: ${event.location.x}, ${event.location.y}',
    );
    emit(CameraPosition(location: event.location, zoom: event.zoom ?? 13.5));
  }

  void _onCameraMoveToCoordinates(
    CameraMoveToCoordinates event,
    Emitter<CameraState> emit,
  ) {
    final location = Location(
      title: 'Custom Location',
      address: '',
      x: event.longitude,
      y: event.latitude,
    );
    emit(CameraPosition(location: location, zoom: event.zoom ?? 13.5));
  }

  void _onCameraReset(CameraReset event, Emitter<CameraState> emit) {
    emit(CameraInitial());
  }
}
