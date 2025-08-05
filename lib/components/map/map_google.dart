import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapGoogle extends StatefulWidget {
  const MapGoogle({super.key});

  @override
  State<MapGoogle> createState() => _MapGoogleState();
}

class _MapGoogleState extends State<MapGoogle> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.4537251, 126.7960716),
    zoom: 1,
  );

  static const CameraPosition _kLake = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(37.43296265331129, -122.08832357078792),
    tilt: 59.440717697143555,
    zoom: 10,
  );
  final Set<Polyline> _polylines = {};
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < 10; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId("${i + 1}"),
          draggable: true,
          onTap: () => print("Marker!"),
          position: LatLng(37.4537251 + i, 126.7960716 + i),
        ),
      );
    }
    _updatePolyline();
  }

  void _updatePolyline() {
    final polyline = Polyline(
      polylineId: PolylineId('route'),
      color: Colors.blue,
      width: 5,
      points: _markers.map((m) => m.position).toList(),
    );
    setState(() {
      _polylines.clear();
      _polylines.add(polyline);
    });
  }

  void _updatePosition(CameraPosition position) {
    var m = _markers.firstWhere(
      (p) => p.markerId == MarkerId('1'),
      orElse: () => Marker(
        markerId: MarkerId('1'),
        position: LatLng(0, 0),
        draggable: true,
      ),
    );
    _markers.remove(m);
    _markers.add(
      Marker(
        markerId: MarkerId('1'),
        position: LatLng(position.target.latitude, position.target.longitude),
        draggable: true,
      ),
    );
    _updatePolyline();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: GoogleMap(
        mapType: MapType.normal,
        markers: Set.from(_markers),
        polylines: _polylines,
        initialCameraPosition: _kGooglePlex,
        onCameraMove: ((position) => _updatePosition(position)),

        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _goToTheLake,
      //   label: const Text('To the lake!'),
      //   icon: const Icon(Icons.directions_boat),
      // ),
    );
  }

  // Future<void> _goToTheLake() async {
  //   final GoogleMapController controller = await _controller.future;
  //   await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  // }
}
