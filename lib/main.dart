import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

import 'screens/screen_home.dart';
import 'screens/screen_map.dart';
import 'screens/screen_naver_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // runApp 실행 이전이면 필요
  await dotenv.load(fileName: ".env");
  // iOS로 환경변수 전달
  await sendEnvToIOS();

  await FlutterNaverMap().init(
    clientId: dotenv.env['NAVER_MAP_CLIENT_KEY'],
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          print("사용량 초과 (message: $message)");
          break;
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          print("인증 실패: $ex");
          break;
      }
    },
  );

  runApp(const MyApp());
}

// iOS로 환경변수 전달하는 함수
Future<void> sendEnvToIOS() async {
  try {
    const platform = MethodChannel('com.moonspace.pj_trip/env');

    final envData = {
      'googleMapsApiKey': dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '',
      'naverMapClientKey': dotenv.env['NAVER_MAP_CLIENT_KEY'] ?? '',
      'naverMapClientSecret': dotenv.env['NAVER_MAP_CLIENT_SECRET'] ?? '',
    };

    await platform.invokeMethod('setEnvData', envData);
    debugPrint('환경변수가 iOS로 전달되었습니다.');
  } catch (e) {
    debugPrint('iOS 환경변수 전달 중 오류: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const ScreenHome(),
        '/map': (context) => const ScreenMap(),
        '/naver_map': (context) => const ScreenNaverMap(),
      },
    );
  }
}
