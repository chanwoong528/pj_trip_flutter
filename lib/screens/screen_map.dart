import 'package:flutter/material.dart';
import 'package:pj_trip/components/map/map_google.dart';
import 'package:pj_trip/components/map/map_naver.dart';
import 'package:pj_trip/components/ui/bot_sheet_single.dart';
import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/screens/screen_search.dart';

class ScreenMap extends StatefulWidget {
  const ScreenMap({super.key, required this.isLocationKorea, this.location});

  final bool isLocationKorea;
  final Location? location;

  @override
  State<ScreenMap> createState() => _ScreenMapState();
}

class _ScreenMapState extends State<ScreenMap> {
  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 바텀 시트를 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.location != null) {
        _showLocationBottomSheet();
      }
    });
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) => BotSheetSingle(location: widget.location!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경에 지도가 전체 화면을 차지
          Positioned.fill(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Expanded(
                  child: widget.isLocationKorea
                      ? MapNaver(location: widget.location)
                      : const MapGoogle(),
                ),
                true
                    ? Container(
                        color: Colors.red,
                        height: MediaQuery.of(context).size.height * 0.5,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          // Positioned.fill(
          //   child: widget.isLocationKorea
          //       ? MapNaver(location: widget.location)
          //       : const MapGoogle(),
          // ),

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

          // 하단에 장소 정보 표시
        ],
      ),
    );
  }
}
