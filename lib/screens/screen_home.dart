import 'package:flutter/material.dart';
import 'package:pj_trip/components/ui/home_carousel.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  void _navigateToMap() {
    Navigator.pushNamed(context, '/map');
  }

  void _navigateToNaverMap() {
    Navigator.pushNamed(context, '/map');
  }

  void addTravel() {
    Navigator.pushNamed(context, '/travel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            HomeCarousel(),
            const SizedBox(height: 20),
            // 여기에 다른 위젯들을 추가할 수 있습니다
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add',
        onPressed: addTravel,
        tooltip: 'Add Travel',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
