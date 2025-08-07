import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pj_trip/store/pods_camera.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapNaverHook extends HookConsumerWidget {
  const MapNaverHook({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapControllerRef = useRef<NaverMapController?>(null);

    final camera = ref.watch(cameraProvider);

    useEffect(() {
      mapControllerRef.value?.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(camera.lat, camera.lng),
          zoom: camera.zoom,
        ),
      );
      return null;
    }, [camera.lat, camera.lng, camera.zoom]);

    final safeAreaPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      body: NaverMap(
        onCameraChange: (cameraUpdate, isAnimation) {
          debugPrint('camera: ${cameraUpdate.payload}');
        },
        options: NaverMapViewOptions(contentPadding: safeAreaPadding),
        onMapReady: (controller) {
          mapControllerRef.value = controller;
          debugPrint('Map controller ready');
        },
      ),
    );
  }
}
