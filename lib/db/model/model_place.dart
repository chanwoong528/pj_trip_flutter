class ModelPlace {
  final int id;
  final int tripId;
  final num placeOrder;
  final String placeName;
  final num placeLatitude;
  final num placeLongitude;
  final String placeAddress;
  final String navigationUrl;

  const ModelPlace({
    required this.id,
    required this.tripId,
    required this.placeOrder,
    required this.placeName,
    required this.placeLatitude,
    required this.placeLongitude,
    required this.placeAddress,
    required this.navigationUrl,
  });
}
