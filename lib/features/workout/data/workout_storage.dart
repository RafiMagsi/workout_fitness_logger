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
    final demoEntries = [
      WorkoutEntry(
        id: 'demo-1',
        timestamp: now.subtract(const Duration(days: 14)),
        exerciseType: ExerciseType.running,
        durationMinutes: 30,
        value: 3.2,
        metricType: FitnessMetricType.move,
        note: 'Easy pace',
      ),
      WorkoutEntry(
        id: 'demo-2',
        timestamp: now.subtract(const Duration(days: 12)),
        exerciseType: ExerciseType.running,
        durationMinutes: 32,
        value: 3.6,
        metricType: FitnessMetricType.move,
        note: 'First hill repeat',
      ),
      WorkoutEntry(
        id: 'demo-3',
        timestamp: now.subtract(const Duration(days: 10)),
        exerciseType: ExerciseType.strength,
        durationMinutes: 40,
        value: 0,
        metricType: FitnessMetricType.activeMinutes,
        note: 'Upper body',
      ),
      WorkoutEntry(
        id: 'demo-4',
        timestamp: now.subtract(const Duration(days: 7)),
        exerciseType: ExerciseType.running,
        durationMinutes: 35,
        value: 4.1,
        metricType: FitnessMetricType.move,
        note: 'Felt strong',
      ),
      WorkoutEntry(
        id: 'demo-5',
        timestamp: now.subtract(const Duration(days: 4)),
        exerciseType: ExerciseType.cycling,
        durationMinutes: 45,
        value: 12.4,
        metricType: FitnessMetricType.move,
        note: 'Long ride',
      ),
      WorkoutEntry(
        id: 'demo-6',
        timestamp: now.subtract(const Duration(days: 2)),
        exerciseType: ExerciseType.running,
        durationMinutes: 38,
        value: 4.6,
        metricType: FitnessMetricType.move,
        note: 'Beat last week',
      ),
    ];
    for (final entry in demoEntries) {
      await addEntry(entry);
    }
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await save();
  }
}
