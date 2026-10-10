import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../domain/workout_entry.dart';
import '../domain/metrics.dart';
import 'workout_entry_serialization.dart';

/// Local storage service for workout entries.
class WorkoutStorage {
  WorkoutStorage._();

  static final WorkoutStorage _instance = WorkoutStorage._();
  static WorkoutStorage get instance => _instance;

  File? _storageFile;
  List<WorkoutEntry> _entries = [];

  Future<File> get _file async {
    if (_storageFile != null) return _storageFile!;
    String baseDir;
    try {
      final dir = await getApplicationDocumentsDirectory();
      baseDir = dir.path;
    } catch (_) {
      // Platform channel unavailable (unit tests / unsupported platform):
      // fall back to a temp directory so the app still works in-memory-ish.
      baseDir = Directory.systemTemp.createTempSync('workout_logger_').path;
    }
    final file = File('$baseDir/workout_entries.json');
    if (!await file.exists()) {
      await file.writeAsString('[]');
    }
    _storageFile = file;
    return file;
  }

  Future<List<WorkoutEntry>> load() async {
    final file = await _file;
    final contents = await file.readAsString();
    if (contents.trim().isEmpty) {
      _entries = [];
      return _entries;
    }
    final List<dynamic> jsonList = jsonDecode(contents) as List<dynamic>;
    _entries = jsonList
        .map((dynamic json) =>
            WorkoutEntryCodec.fromJson(json as Map<String, dynamic>))
        .toList();
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _entries;
  }

  Future<void> save() async {
    final file = await _file;
    final jsonList = _entries.map(WorkoutEntryCodec.toJson).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  List<WorkoutEntry> get entries => List.unmodifiable(_entries);

  /// Adds a new entry and persist it.
  Future<void> addEntry(WorkoutEntry entry) async {
    _entries.insert(0, entry);
    await save();
  }

  /// Remove an entry by id.
  Future<void> removeEntry(String id) async {
    _entries = _entries.where((e) => e.id != id).toList();
    await save();
  }

  /// Seed demo data if storage is empty.
  Future<void> seedDemoIfNeeded() async {
    final loaded = await load();
    if (loaded.isNotEmpty) return;
    final now = DateTime.now();
    DateTime at(int daysAgo, int hour, [int minute = 0]) {
      final base = now.subtract(Duration(days: daysAgo));
      return DateTime(base.year, base.month, base.day, hour, minute);
    }

    final demoEntries = [
      // Today — so rings, tiles, and streak light up on first launch.
      WorkoutEntry(
        id: 'demo-t1',
        timestamp: at(0, 8, 15),
        exerciseType: ExerciseType.running,
        durationMinutes: 35,
        value: 320,
        metricType: FitnessMetricType.move,
        note: 'Morning pace',
      ),
      WorkoutEntry(
        id: 'demo-t2',
        timestamp: at(0, 12, 40),
        exerciseType: ExerciseType.walking,
        durationMinutes: 15,
        value: 90,
        metricType: FitnessMetricType.move,
        note: 'Lunch walk',
      ),
      WorkoutEntry(
        id: 'demo-t3',
        timestamp: at(0, 18, 20),
        exerciseType: ExerciseType.strength,
        durationMinutes: 40,
        value: 40,
        metricType: FitnessMetricType.activeMinutes,
        note: 'Push day',
      ),
      // Yesterday — keeps the streak alive.
      WorkoutEntry(
        id: 'demo-y1',
        timestamp: at(1, 19, 0),
        exerciseType: ExerciseType.cycling,
        durationMinutes: 45,
        value: 480,
        metricType: FitnessMetricType.move,
        note: 'Long ride',
      ),
      WorkoutEntry(
        id: 'demo-1',
        timestamp: at(3, 7, 30),
        exerciseType: ExerciseType.running,
        durationMinutes: 30,
        value: 280,
        metricType: FitnessMetricType.move,
        note: 'Easy pace',
      ),
      WorkoutEntry(
        id: 'demo-2',
        timestamp: at(5, 17, 45),
        exerciseType: ExerciseType.strength,
        durationMinutes: 40,
        value: 40,
        metricType: FitnessMetricType.activeMinutes,
        note: 'Upper body',
      ),
      WorkoutEntry(
        id: 'demo-4',
        timestamp: at(7, 8, 0),
        exerciseType: ExerciseType.running,
        durationMinutes: 35,
        value: 360,
        metricType: FitnessMetricType.move,
        note: 'Felt strong',
      ),
      WorkoutEntry(
        id: 'demo-5',
        timestamp: at(10, 9, 30),
        exerciseType: ExerciseType.cycling,
        durationMinutes: 60,
        value: 520,
        metricType: FitnessMetricType.move,
        note: 'Hill loop',
      ),
      WorkoutEntry(
        id: 'demo-6',
        timestamp: at(12, 18, 10),
        exerciseType: ExerciseType.yoga,
        durationMinutes: 25,
        value: 25,
        metricType: FitnessMetricType.activeMinutes,
        note: 'Recovery flow',
      ),
    ];
    for (final entry in demoEntries) {
      await addEntry(entry);
    }
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await save();
  }
}
