import 'package:flutter/material.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _navigateToMap() {
    Navigator.pushNamed(context, '/map');
  }

  void _navigateToNaverMap() {
    Navigator.pushNamed(context, '/map');
  }

  void addTravel() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: _incrementCounter,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),

      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _navigateToNaverMap,
            tooltip: 'naver map',
            child: const Icon(Icons.map),
          ),
          FloatingActionButton(
            heroTag: 'map',
            onPressed: _navigateToMap,
            tooltip: 'Map',
            child: const Icon(Icons.map),
          ),

          FloatingActionButton(
            heroTag: 'add',
            onPressed: _incrementCounter,
            tooltip: 'Map',
            child: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
