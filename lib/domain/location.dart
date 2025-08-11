import 'package:flutter/material.dart';
import 'package:pj_trip/db/model/model_place.dart';

class Location {
  final String address;
  final String title;
  final num x;
  final num y;
  final Bounds? boundingbox;

  Location({
    required this.address,
    required this.title,
    required this.x,
    required this.y,
    this.boundingbox,
  });

  factory Location.kakaoFromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address_name'],
      title: json['place_name'],
      x: double.parse(json['x']),
      y: double.parse(json['y']),
    );
  }
  factory Location.googleFromJson(Map<String, dynamic> json) {
    return Location(
      address: json['formattedAddress'],
      title: json['displayName']['text'] ?? '',
      x: json['location']['latitude'],
      y: json['location']['longitude'],
    );
  }

  factory Location.nominatimFromJson(Map<String, dynamic> json) {
    debugPrint(
      'nominatimFromJson:>>> ${json['boundingbox'][0]} ${json['boundingbox'][1]} ${json['boundingbox'][2]} ${json['boundingbox'][3]}',
    );
    return Location(
      address: json['address']['country'] ?? '',
      title:
          json['address']['city'] ??
          json['address']['province'] ??
          json['address']['state'] ??
          json['address']['country'] ??
          json['address']['country_code'] ??
          '',
      x: double.parse(json['lon'] ?? '0'),
      y: double.parse(json['lat'] ?? '0'),
      boundingbox: Bounds(
        lowLatitude: double.parse(json['boundingbox'][0] ?? '0'),
        lowLongitude: double.parse(json['boundingbox'][2] ?? '0'),
        highLatitude: double.parse(json['boundingbox'][1] ?? '0'),
        highLongitude: double.parse(json['boundingbox'][3] ?? '0'),
      ),
    );
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      address: map['address'] ?? '',
      title: map['title'] ?? '',
      x: map['x'] ?? 0,
      y: map['y'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.address == address &&
        other.title == title &&
        other.x == x &&
        other.y == y;
  }

  @override
  int get hashCode {
    return address.hashCode ^ title.hashCode ^ x.hashCode ^ y.hashCode;
  }

  /**

kakao  response
{
  "address_name":"강원특별자치도 원주시 문막읍 건등리 383-36",
  "category_group_code":"FD6",
  "category_group_name":"음식점",
  "category_name":"음식점 \u003e 한식 \u003e 육류,고기",
  "distance":"",
  "id":"16938888",
  "phone":"033-735-3337",
  "place_name":"123",
  "place_url":"http://place.map.kakao.com/16938888",
  "road_address_name":"강원특별자치도 원주시 문막읍 왕건로 33-8",
  "x":"127.829044693722",
  "y":"37.322199411427"
}

 */
}

final googleResponse = {
  "results": [
    {
      "business_status": "OPERATIONAL",
      "formatted_address": "7 Chome-3-1 Hongo, Bunkyo City, Tokyo 113-8654 일본",
      "geometry": {
        "location": {"lat": 35.7138159, "lng": 139.7627345},
        "viewport": {
          "northeast": {"lat": 35.7199335, "lng": 139.7663317},
          "southwest": {"lat": 35.70503430000001, "lng": 139.7560053},
        },
      },
      "icon":
          "https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/school-71.png",
      "icon_background_color": "#7B9EB0",
      "icon_mask_base_uri":
          "https://maps.gstatic.com/mapfiles/place_api/icons/v2/school_pinlet",
      "name": "도쿄 대학",
      "opening_hours": {"open_now": true},
      "photos": [
        {
          "height": 3024,
          "html_attributions": [
            "\u003ca href=\"https://maps.google.com/maps/contrib/105340936840905234417\"\u003eA Google User\u003c/a\u003e",
          ],
          "photo_reference":
              "ATKogpfvdUH4iWrhlsuxwxZ5YeTHAJh0gVtYlma0pissY_lM6PSoFql63Gf1cxRLVFGZqtVQnDQCwP0ImWcZb_vtwxDF1G6dSfiFEksWSWn6-O7klCqK0RN3WxXpNN1w_TMjn4jO1Py9yyufy8F-Tm9mfv7h16U9d2zKx1ktWdCoXk-V2OgrVvI90UBEocgfQCvW7FnRrO7c5bORPhVhpNmnlv82wiXqziY1yjAYjI3I3ddMNQUiZgQx3V9xfqh4EzR7ircIHkw2uYeAAss30q2gt1Gy0KSHjTEMbWF-vmTrc7M3slPbCXiycDTp6nCpiW17TMITM0aqSMlvQk-mEcCuXLsFhdAz2SbvoAoCYAyY-oBf-w8Sz9kIv-o3px0yDQe40ueL_YJS2vzs0a-4nypwWMww8X9gDjQq7lLEtyS_JaJaK55Xeiwque34y5pvgcWfWfIyg5UvsY-RsrNfoTqgPhF6FiK-NObaKnMMKYL0C-5I7xeChpx5MOhQV7OVVkHPj3Xe0Hu5PPP6BRz72_QcUUGNIwZu6TAtt5ni4n1oCQgl2_zZIUGGZyV6AcZK0DPzzAjibT35",
          "width": 4032,
        },
      ],
      "place_id": "ChIJo24g-i-MGGARlboTg0kH5DA",
      "plus_code": {
        "compound_code": "PQ77+G3 분쿄구 일본 도쿄도",
        "global_code": "8Q7XPQ77+G3",
      },
      "rating": 4.5,
      "reference": "ChIJo24g-i-MGGARlboTg0kH5DA",
      "types": ["university", "point_of_interest", "establishment"],
      "user_ratings_total": 2677,
    },
  ],
  "status": "OK",
};
