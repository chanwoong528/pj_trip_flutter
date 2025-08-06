import 'package:pj_trip/domain/location.dart';

double getZoomFromPlaces(List<Map<String, dynamic>> places) {
  if (places.isEmpty) return 13.5;

  // 위도/경도의 최소/최대값 찾기
  double minLat = double.infinity;
  double maxLat = -double.infinity;
  double minLng = double.infinity;
  double maxLng = -double.infinity;

  for (final place in places) {
    final lat = (place['placeLatitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (place['placeLongitude'] as num?)?.toDouble() ?? 0.0;

    if (lat != 0.0 && lng != 0.0) {
      minLat = minLat > lat ? lat : minLat;
      maxLat = maxLat < lat ? lat : maxLat;
      minLng = minLng > lng ? lng : minLng;
      maxLng = maxLng < lng ? lng : maxLng;
    }
  }

  // 유효한 좌표가 없으면 기본 줌
  if (minLat == double.infinity || maxLat == -double.infinity) {
    return 13.5;
  }

  // 위도/경도 차이 계산
  final latDiff = maxLat - minLat;
  final lngDiff = maxLng - minLng;
  final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

  // 차이에 따른 줌 레벨 계산
  if (maxDiff > 1.0) return 8.0; // 매우 넓은 영역
  if (maxDiff > 0.5) return 9.0; // 넓은 영역
  if (maxDiff > 0.2) return 10.0; // 중간 영역
  if (maxDiff > 0.1) return 11.0; // 작은 영역
  if (maxDiff > 0.05) return 12.0; // 매우 작은 영역
  if (maxDiff > 0.02) return 13.0; // 세밀한 영역
  return 14.0; // 가장 세밀한 영역
}

Location getAvgCenterLocation(List<Map<String, dynamic>> places) {
  double totalLat = 0;
  double totalLng = 0;
  int validCount = 0;

  for (final place in places) {
    final lat = (place['placeLatitude'] as num?)?.toDouble() ?? 37.5;
    final lng = (place['placeLongitude'] as num?)?.toDouble() ?? 127.0;

    if (lat != 0.0 && lng != 0.0) {
      totalLat += lat;
      totalLng += lng;
      validCount++;
    }
  }

  final centerLat = totalLat / validCount;
  final centerLng = totalLng / validCount;
  return Location(title: 'Center', x: centerLng, y: centerLat, address: '');
}
