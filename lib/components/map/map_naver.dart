import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pj_trip/domain/location.dart';

class MapNaver extends StatelessWidget {
  const MapNaver({super.key, this.location});

  final Location? location;

  @override
  Widget build(BuildContext context) {
    final centerPosition = NLatLng(
      location?.y.toDouble() ?? 37.5666,
      location?.x.toDouble() ?? 126.979,
    );
    final safeAreaPadding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: NaverMap(
        options: NaverMapViewOptions(
          contentPadding:
              safeAreaPadding, // 화면의 SafeArea에 중요 지도 요소가 들어가지 않도록 설정하는 Padding. 필요한 경우에만 사용하세요.
          initialCameraPosition: NCameraPosition(
            target: centerPosition,
            zoom: 14,
          ),
        ),
        onMapReady: (controller) {
          final marker = NMarker(
            id: "location", // Required
            position: centerPosition, // Required
            caption: NOverlayCaption(text: location?.title ?? ""), // Optional
          );
          controller.addOverlay(marker); // 지도에 마커를 추가
        },
      ),
    );
  }
}
