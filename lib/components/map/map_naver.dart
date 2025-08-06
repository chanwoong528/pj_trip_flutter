import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/blocs/camera/camera_bloc.dart';
import 'package:pj_trip/blocs/location/location_bloc.dart';
import 'package:pj_trip/utils/camera_math.dart';
import 'package:pj_trip/utils/util.dart';

class MapNaver extends StatefulWidget {
  const MapNaver({super.key, this.location, this.places});

  final Location? location;
  final List<Map<String, dynamic>>? places;

  @override
  State<MapNaver> createState() => _MapNaverState();
}

class _MapNaverState extends State<MapNaver> {
  NaverMapController? _mapController;

  List<NMarker> _placeMarkers = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(MapNaver oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!isListSame(oldWidget.places ?? [], widget.places ?? [])) {
      _updatePlaceMarkers();
    }
  }

  void _updateSearchedMarkers(Location? selectedLocation) {
    if (_mapController == null || selectedLocation == null) return;
    try {
      final latitude = selectedLocation.y;
      final longitude = selectedLocation.x;

      final position = NLatLng(latitude.toDouble(), longitude.toDouble());
      final marker = NMarker(
        id: "searched_marker",
        position: position,
        caption: NOverlayCaption(text: selectedLocation.title),
      );
      _mapController!.addOverlay(marker);
    } catch (e) {
      debugPrint('Error updating searched markers: $e');
    }
  }

  void _updatePlaceMarkers() {
    if (_mapController == null) return;

    try {
      // 기존 장소 마커들 제거
      _mapController!.clearOverlays();

      final locationState = context.read<LocationBloc>().state;
      if (locationState is LocationLoaded) {
        _updateSearchedMarkers(locationState.selectedLocation);
      }
      if (widget.places != null && widget.places!.isNotEmpty) {
        for (final place in widget.places!) {
          final placeName = place['placeName'] as String? ?? 'Unknown Place';
          // 데이터베이스 필드명에 맞춰 수정
          final latitude = place['placeLatitude'] as num? ?? 0.0;
          final longitude = place['placeLongitude'] as num? ?? 0.0;

          final position = NLatLng(latitude.toDouble(), longitude.toDouble());
          final marker = NMarker(
            id: "place_${place['id']}",
            position: position,
            caption: NOverlayCaption(text: placeName),
            iconTintColor: Colors.red,
          );

          _mapController!.addOverlay(marker);
          _placeMarkers.add(marker);
        }
        // _moveCameraToPlaces(widget.places!);
      } else {
        debugPrint('No places to display');
      }
    } catch (e) {
      debugPrint('Error updating place markers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, locationState) {
        // LocationBloc 상태 변경 시 실행할 로직
        if (locationState is LocationLoaded &&
            locationState.selectedLocation != null) {
          _updateSearchedMarkers(locationState.selectedLocation);
        }
      },
      child: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, locationState) {
          final selectedLocation = locationState is LocationLoaded
              ? locationState.selectedLocation
              : widget.location;

          debugPrint(
            '=== MapNaver > build > centerPosition ===\n${widget.places?.length}',
          );

          final centerPosition = NLatLng(
            selectedLocation?.y.toDouble() ?? 34.0,
            selectedLocation?.x.toDouble() ?? 126.0,
          );

          debugPrint(
            '=== MapNaver > build > centerPosition ===\n${selectedLocation?.y.toDouble() ?? 34.0}',
          );
          debugPrint(
            '=== MapNaver > build > centerPosition ===\n${selectedLocation?.x.toDouble() ?? 126.0}',
          );

          final cameraPosition = NCameraPosition(
            target: centerPosition,
            zoom: 14,
          );

          final safeAreaPadding = MediaQuery.paddingOf(context);
          return BlocListener<CameraBloc, CameraState>(
            listener: (context, state) {
              if (state is CameraPosition && _mapController != null) {
                _updateCameraFromBloc(state);
              }
            },
            child: Scaffold(
              body: NaverMap(
                options: NaverMapViewOptions(
                  contentPadding: safeAreaPadding,
                  initialCameraPosition: cameraPosition,
                ),
                onMapReady: (controller) {
                  _mapController = controller;
                  _updatePlaceMarkers();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateCameraFromBloc(CameraPosition state) {
    if (_mapController == null) return;

    try {
      final centerPosition = NLatLng(
        state.location.y.toDouble(),
        state.location.x.toDouble(),
      );

      final cameraUpdate = NCameraUpdate.withParams(
        target: centerPosition,
        zoom: state.zoom,
      );

      _mapController!.updateCamera(cameraUpdate);
      debugPrint(
        'Camera moved to: ${state.location.title} at (${state.location.x}, ${state.location.y}) with zoom: ${state.zoom}',
      );
    } catch (e) {
      debugPrint('Error updating camera from BLoC: $e');
    }
  }
}
