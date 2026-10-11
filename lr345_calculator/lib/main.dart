import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Шушарев Вариант 9 — Равномерное ускорение',
      home: const FirstScreen(),
    );
  }
}

// Экран 1: ввод данных
class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  final _v1 = TextEditingController();
  final _v2 = TextEditingController();
  final _t = TextEditingController();
  bool _agreed = false;
  final _formKey = GlobalKey<FormState>();

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecondScreen(
          v1: double.parse(_v1.text),
          v2: double.parse(_v2.text),
          t: double.parse(_t.text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вариант 9: ввод данных')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _v1,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Начальная скорость v1, м/с',
                  hintText: 'например 10',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите v1';
                  if (double.tryParse(v) == null) return 'v1 должно быть числом';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _v2,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Конечная скорость v2, м/с',
                  hintText: 'например 20',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите v2';
                  if (double.tryParse(v) == null) return 'v2 должно быть числом';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _t,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Время t, с',
                  hintText: 'например 5',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите t';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 't должно быть числом больше нуля';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _agreed,
                title: const Text('Я согласен предоставить данные для расчёта'),
                onChanged: (v) => setState(() => _agreed = v ?? false),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _agreed ? _next : null,
                child: const Text('Дальше'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Экран 2: результаты
class SecondScreen extends StatelessWidget {
  const SecondScreen({required this.v1, required this.v2, required this.t, super.key});

  final double v1;
  final double v2;
  final double t;

  double get a => (v2 - v1) / t; // ускорение
  double get s => (v1 + v2) / 2 * t; // перемещение
  double get vAvg => (v1 + v2) / 2; // средняя скорость

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вариант 9: результаты')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Дано: v1 = $v1 м/с, v2 = $v2 м/с, t = $t с',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Ускорение: a = (v2 - v1) / t',
                style: const TextStyle(fontSize: 14)),
            Text('a = ${a.toStringAsFixed(2)} м/с²',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Перемещение: s = (v1 + v2) / 2 * t',
                style: const TextStyle(fontSize: 14)),
            Text('s = ${s.toStringAsFixed(2)} м',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Средняя скорость: v = (v1 + v2) / 2',
                style: const TextStyle(fontSize: 14)),
            Text('v = ${vAvg.toStringAsFixed(2)} м/с',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}
