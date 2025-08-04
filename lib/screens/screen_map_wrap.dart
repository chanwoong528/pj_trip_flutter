import 'package:flutter/material.dart';
import 'package:pj_trip/screens/screen_google_map.dart';
import 'package:pj_trip/screens/screen_naver_map.dart';
import 'package:pj_trip/screens/screen_search.dart';

class ScreenMapWrap extends StatelessWidget {
  const ScreenMapWrap({super.key, required this.isLocationKorea});

  final bool isLocationKorea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경에 지도가 전체 화면을 차지
          Positioned.fill(
            child: isLocationKorea
                ? const ScreenNaverMap()
                : const ScreenGoogleMap(),
          ),
          // 상단에 검색바와 백버튼 오버레이
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ScreenSearch(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return child;
                                },
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Text(
                              '장소를 검색하세요',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
