import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Шушарев Вариант 9 — Cubit (смена состояний)',
      home: BlocProvider(
        create: (context) => MotionCubit(),
        child: const MotionScreen(),
      ),
    );
  }
}

// Состояния Cubit
abstract class MotionState {}

class MotionInputState extends MotionState {
  MotionInputState();
}

class MotionResultsState extends MotionState {
  MotionResultsState({required this.v1, required this.v2, required this.t});
  final double v1;
  final double v2;
  final double t;
}

// Все вычисления живут в Cubit
class MotionCubit extends Cubit<MotionState> {
  MotionCubit() : super(MotionInputState());

  void toInput() => emit(MotionInputState());

  void toResults(double v1, double v2, double t) =>
      emit(MotionResultsState(v1: v1, v2: v2, t: t));
}

// Один экран, но представление меняется по состоянию — вместо навигации
class MotionScreen extends StatelessWidget {
  const MotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вариант 9: Cubit — смена состояний вместо экранов'),
      ),
      body: BlocBuilder<MotionCubit, MotionState>(
        builder: (context, state) {
          if (state is MotionInputState) {
            return const _InputView();
          }
          final r = state as MotionResultsState;
          return _ResultsView(v1: r.v1, v2: r.v2, t: r.t);
        },
      ),
    );
  }
}

// «Экран ввода» — на самом деле состояние
class _InputView extends StatefulWidget {
  const _InputView();

  @override
  State<_InputView> createState() => _InputViewState();
}

class _InputViewState extends State<_InputView> {
  final _v1 = TextEditingController();
  final _v2 = TextEditingController();
  final _t = TextEditingController();
  bool _agreed = false;
  final _formKey = GlobalKey<FormState>();

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.read<MotionCubit>().toResults(
      double.parse(_v1.text),
      double.parse(_v2.text),
      double.parse(_t.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
    );
  }
}

// «Экран результатов» — на самом деле состояние
class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.v1, required this.v2, required this.t});
  final double v1;
  final double v2;
  final double t;

  double get a => (v2 - v1) / t;
  double get s => (v1 + v2) / 2 * t;
  double get vAvg => (v1 + v2) / 2;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            onPressed: () => context.read<MotionCubit>().toInput(),
            child: const Text('Назад (сменить состояние)'),
          ),
        ],
      ),
    );
  }
}
