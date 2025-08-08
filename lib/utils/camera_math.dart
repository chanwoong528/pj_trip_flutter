// import 'package:flutter/material.dart';

import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/db/model/model_place.dart';

import 'dart:math';

double getZoomFromPlacesByPlacesModel(List<ModelPlace> places) {
  if (places.isEmpty) return 13.5;

  // 위도/경도의 최소/최대값 찾기
  double minLat = double.infinity;
  double maxLat = -double.infinity;
  double minLng = double.infinity;
  double maxLng = -double.infinity;

  for (final place in places) {
    final lat = place.placeLatitude.toDouble();
    final lng = place.placeLongitude.toDouble();

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

  // 표준 줌 레벨 계산 공식 (바운딩 박스 기반)
  // zoom = log2(360 / maxDiff) - 1
  // 또는 더 정확한 공식: zoom = log2(256 / maxDiff) - 1
  final zoom = (log(256 / maxDiff) / log(2)) - 1;

  // 줌 레벨 범위 제한 (너무 가깝거나 멀지 않게)
  final clampedZoom = zoom.clamp(8.0, 15.0);

  return clampedZoom;
}

Location getAvgCenterLocationByPlacesModel(List<ModelPlace> places) {
  double totalLat = 0;
  double totalLng = 0;
  int validCount = 0;

  for (final place in places) {
    final lat = place.placeLatitude.toDouble();
    final lng = place.placeLongitude.toDouble();

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

bool isLocationInKorea(Location location) {
  // 주소에 한국 관련 키워드가 있는지 확인
  final koreanKeywords = ['한국', '대한민국', 'Korea', 'South Korea', 'KR'];
  final address = location.address.toLowerCase();
  return koreanKeywords.any(
    (keyword) => address.contains(keyword.toLowerCase()),
  );
}

bool isInKoreaByPosition(double latitude, double longitude) {
  return latitude > 33 && latitude < 38.5 && longitude > 124 && longitude < 132;
}
