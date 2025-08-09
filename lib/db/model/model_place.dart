class Bounds {
  final double lowLatitude;
  final double lowLongitude;
  final double highLatitude;
  final double highLongitude;

  Bounds({
    required this.lowLatitude,
    required this.lowLongitude,
    required this.highLatitude,
    required this.highLongitude,
  });
}

class ModelPlace {
  final int id;
  final int tripId;
  final num placeOrder;
  final String placeName;
  final num placeLatitude;
  final num placeLongitude;
  final String placeAddress;
  final String navigationUrl;

  ModelPlace({
    required this.id,
    required this.tripId,
    required this.placeOrder,
    required this.placeName,
    required this.placeLatitude,
    required this.placeLongitude,
    required this.placeAddress,
    required this.navigationUrl,
  });

  factory ModelPlace.fromJson(Map<String, dynamic> json) {
    return ModelPlace(
      id: json['id'] as int? ?? 0,
      tripId: json['tripId'] as int? ?? 0,
      placeOrder: json['placeOrder'] as num? ?? 0,
      placeName: json['placeName'] as String? ?? '',
      placeLatitude: json['placeLatitude'] as num? ?? 0.0,
      placeLongitude: json['placeLongitude'] as num? ?? 0.0,
      placeAddress: json['placeAddress'] as String? ?? '',
      navigationUrl: json['navigationUrl'] as String? ?? '',
    );
  }

  factory ModelPlace.fromKakao(
    Map<String, dynamic> json,
    int tripId,
    int placeOrder,
  ) {
    return ModelPlace(
      id: json['id'] as int? ?? 0,
      placeName: json['place_name'] as String? ?? '',
      placeLatitude: json['y'] as num? ?? 0.0,
      placeLongitude: json['x'] as num? ?? 0.0,
      placeAddress: json['address_name'] as String? ?? '',
      navigationUrl: json['place_url'] as String? ?? '',

      tripId: tripId,
      placeOrder: placeOrder,
    );
  }

  ModelPlace copyWith({
    int? id,
    int? tripId,
    num? placeOrder,
    String? placeName,
    num? placeLatitude,
    num? placeLongitude,
    String? placeAddress,
    String? navigationUrl,
  }) {
    return ModelPlace(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      placeOrder: placeOrder ?? this.placeOrder,
      placeName: placeName ?? this.placeName,
      placeLatitude: placeLatitude ?? this.placeLatitude,
      placeLongitude: placeLongitude ?? this.placeLongitude,
      placeAddress: placeAddress ?? this.placeAddress,
      navigationUrl: navigationUrl ?? this.navigationUrl,
    );
  }
}
