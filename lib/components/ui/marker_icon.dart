import 'package:flutter/material.dart';

class MarkerIcon extends StatelessWidget {
  const MarkerIcon({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),
      ),
    );
  }
}
