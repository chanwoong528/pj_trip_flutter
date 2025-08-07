class Location {
  final String address;
  final String title;
  final num x;
  final num y;

  Location({
    required this.address,
    required this.title,
    required this.x,
    required this.y,
  });

  factory Location.kakaoFromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address_name'],
      title: json['place_name'],
      x: double.parse(json['x']),
      y: double.parse(json['y']),
    );
  }

  factory Location.nominatimFromJson(Map<String, dynamic> json) {
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
