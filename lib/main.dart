import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_config/flutter_config.dart';

import 'screens/screen_home.dart';
import 'screens/screen_map.dart';
import 'screens/screen_naver_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // runApp 실행 이전이면 필요

  await dotenv.load(fileName: ".env");
  await FlutterConfig.loadEnvVariables();

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
