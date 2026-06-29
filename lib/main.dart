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
/// Prefers the curated CC0 Lichess library (`assets/puzzles/puzzles.json`,
/// produced by `tool/curate_puzzles.dart`) and falls back to the tiny sample if
/// it's missing/empty. On total failure it returns an empty repository so the
/// app still starts and the trainer shows its empty state, not a blank screen.
Future<PuzzleRepository> _loadPuzzleRepository() async {
  for (final asset in const [PuzzleSeeder.libraryAsset, PuzzleSeeder.sampleAsset]) {
    try {
      final json = await rootBundle.loadString(asset);
      final puzzles = (jsonDecode(json) as List)
          .cast<Map<String, dynamic>>()
          .map(TacticsPuzzle.fromJson)
          .toList();
      if (puzzles.isNotEmpty) return InMemoryPuzzleRepository(puzzles);
    } catch (error, stackTrace) {
      debugPrint('Puzzle asset "$asset" failed to load: $error\n$stackTrace');
    }
  }
  return InMemoryPuzzleRepository(const []);
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
