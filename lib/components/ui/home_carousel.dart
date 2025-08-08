import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pj_trip/constant/constant.dart';
import 'package:pj_trip/screens/screen_travel.dart';

class HomeCarousel extends StatelessWidget {
  HomeCarousel({super.key});

  final CarouselController carouselController = CarouselController();

  final List<Map<String, dynamic>> representativeTravels =
      REPRESENTATIVE_TRAVEL_NAME;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200, // 명확한 높이 제약 추가
          child: CarouselSlider(
            items: representativeTravels
                .where((e) => e['image'] != null) // null 체크 추가
                .map(
                  (e) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScreenTravelHook(travelName: e['name']),
                            ),
                          );
                        },
                        child: Image.asset(
                          e['image'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              viewportFraction: 0.8,
              height: 200, // CarouselOptions에도 높이 추가
            ),
          ),
        ),
      ],
    );
  }
}
