import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/content/puzzle_seeder.dart';
import 'domain/tactics/tactics.dart';
import 'features/game/board_screen.dart';
import 'features/tactics/tactics_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await _loadPuzzleRepository();
  runApp(
    ProviderScope(
      overrides: [puzzleRepositoryProvider.overrideWithValue(repository)],
      child: const SuperChessApp(),
    ),
  );
}

/// Loads the bundled puzzle library into the cross-platform in-memory
/// repository (no SQLite needed).
///
/// The bundled sample is a temporary placeholder library until the curated CC0
/// Lichess set (produced by `tool/curate_puzzles.dart` -> `assets/puzzles/
/// puzzles.json`) is bundled and loaded here instead.
///
/// On any load/parse failure this logs a diagnostic and returns an empty
/// repository so the app still starts and the trainer shows its empty state
/// rather than a blank screen.
Future<PuzzleRepository> _loadPuzzleRepository() async {
  try {
    final json = await rootBundle.loadString(PuzzleSeeder.sampleAsset);
    final puzzles = (jsonDecode(json) as List)
        .cast<Map<String, dynamic>>()
        .map(TacticsPuzzle.fromJson)
        .toList();
    return InMemoryPuzzleRepository(puzzles);
  } catch (error, stackTrace) {
    debugPrint('Failed to load puzzle library: $error\n$stackTrace');
    return InMemoryPuzzleRepository(const []);
  }
}

class SuperChessApp extends StatelessWidget {
  const SuperChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6E8C57)),
        useMaterial3: true,
      ),
      home: const BoardScreen(),
    );
  }
}
