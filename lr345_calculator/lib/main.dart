import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // FFI нужен только на десктопе. На Android/iOS используется нативный sqflite.
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => MotionCubit()),
        BlocProvider(create: (context) => HistoryCubit()),
      ],
      child: MaterialApp(
        title: 'Шушарев Вариант 9 — Cubit + SQLite + SharedPreferences',
        home: const MotionScreen(),
      ),
    );
  }
}

// ---------- Результат расчёта ----------
class CalcResult {
  CalcResult({this.id, required this.v1, required this.v2, required this.t});
  final int? id;
  final double v1;
  final double v2;
  final double t;
  double get a => (v2 - v1) / t;
  double get s => (v1 + v2) / 2 * t;
  double get vAvg => (v1 + v2) / 2;
}

// ---------- SQLite ----------
Future<Database> _db() async {
  final path = p.join(await getDatabasesPath(), 'results.db');
  final db = await openDatabase(path);
  await db.execute(
    'CREATE TABLE IF NOT EXISTS results ('
    'id INTEGER PRIMARY KEY AUTOINCREMENT, '
    'v1 REAL NOT NULL, '
    'v2 REAL NOT NULL, '
    't REAL NOT NULL, '
    'created_at TEXT)',
  );
  return db;
}

// ---------- MotionCubit (ввод -> результат, сохраняет в БД) ----------
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

class MotionCubit extends Cubit<MotionState> {
  MotionCubit() : super(MotionInputState());

  void toInput() => emit(MotionInputState());

  Future<void> toResults(double v1, double v2, double t) async {
    // Сохраняем расчёт в SQLite
    final db = await _db();
    await db.insert('results', {
      'v1': v1,
      'v2': v2,
      't': t,
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.close();
    emit(MotionResultsState(v1: v1, v2: v2, t: t));
  }
}

// ---------- HistoryCubit (загружает историю из SQLite) ----------
abstract class HistoryState {}

class HistoryLoading extends HistoryState {
  HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  HistoryLoaded(this.items);
  final List<CalcResult> items;
}

class HistoryError extends HistoryState {
  HistoryError(this.message);
  final String message;
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(HistoryLoading());

  Future<void> load() async {
    emit(HistoryLoading());
    try {
      final db = await _db();
      final rows = await db.query('results', orderBy: 'id DESC');
      final items = rows
          .map((m) => CalcResult(
                id: m['id'] as int,
                v1: (m['v1'] as num).toDouble(),
                v2: (m['v2'] as num).toDouble(),
                t: (m['t'] as num).toDouble(),
              ))
          .toList();
      await db.close();
      emit(HistoryLoaded(items));
    } catch (e) {
      emit(HistoryError('$e'));
    }
  }
}

// ---------- Главный экран (состояния, как в ЛР4) ----------
class MotionScreen extends StatelessWidget {
  const MotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вариант 9: Cubit + SQLite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'История расчётов',
            onPressed: () {
              context.read<HistoryCubit>().load();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
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

// «Экран ввода» (состояние); SharedPreferences помнит согласие
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

  @override
  void initState() {
    super.initState();
    // Восстанавливаем «согласие» из SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      final v = prefs.getBool('agreed') ?? false;
      if (v != _agreed) setState(() => _agreed = v);
    });
  }

  void _setAgreed(bool? v) {
    final nv = v ?? false;
    setState(() => _agreed = nv);
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('agreed', nv));
  }

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
              onChanged: _setAgreed,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _agreed ? _next : null,
              child: const Text('Дальше (сохранить в БД)'),
            ),
          ],
        ),
      ),
    );
  }
}

// «Экран результатов» (состояние)
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
            child: const Text('Новый расчёт (сменить состояние)'),
          ),
        ],
      ),
    );
  }
}

// Экран истории (загружается из SQLite через HistoryCubit)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История расчётов')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryError) {
            return Center(child: Text('Ошибка: ${state.message}'));
          }
          final loaded = state as HistoryLoaded;
          if (loaded.items.isEmpty) {
            return const Center(child: Text('История пуста'));
          }
          return ListView.builder(
            itemCount: loaded.items.length,
            itemBuilder: (context, i) {
              final r = loaded.items[i];
              return ListTile(
                title:
                    Text('v1 = ${r.v1} м/с   v2 = ${r.v2} м/с   t = ${r.t} с'),
                subtitle: Text(
                    'a = ${r.a.toStringAsFixed(2)} м/с²   '
                    's = ${r.s.toStringAsFixed(2)} м   '
                    'v = ${r.vAvg.toStringAsFixed(2)} м/с'),
              );
            },
          );
        },
      ),
    );
  }
}
