import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Шушарев Вариант 9 — Wrap и контейнеры',
      home: WrapScreen(),
    );
  }
}

// Описание одного контейнера
class BoxTile {
  const BoxTile(this.icon, this.color, this.width, this.height, this.margin);
  final IconData icon;
  final Color color;
  final double width;
  final double height;
  final double margin;
}

class WrapScreen extends StatelessWidget {
  const WrapScreen({super.key});

  // Вариант 9: 5-6 контейнеров, у каждого свои размер, цвет, margin и иконка
  static const List<BoxTile> boxes = [
    BoxTile(Icons.home, Colors.red, 120, 120, 12),
    BoxTile(Icons.star, Colors.blue, 100, 100, 10),
    BoxTile(Icons.favorite, Colors.green, 140, 140, 15),
    BoxTile(Icons.settings, Colors.orange, 110, 110, 8),
    BoxTile(Icons.notifications, Colors.purple, 130, 130, 20),
    BoxTile(Icons.search, Colors.teal, 90, 90, 5),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вариант 9: Wrap с контейнерами'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '5-6 контейнеров в Wrap. У каждого: размер, цвет, margin и иконка внутри.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final b in boxes)
                  Container(
                    width: b.width,
                    height: b.height,
                    margin: EdgeInsets.all(b.margin),
                    color: b.color,
                    alignment: Alignment.center,
                    child: Icon(b.icon, color: Colors.white, size: 36),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
