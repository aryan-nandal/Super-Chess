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
  runApp(ProviderScope(
    overrides: [puzzleRepositoryProvider.overrideWithValue(repository)],
    child: const SuperChessApp(),
  ));
}

/// Loads the bundled puzzle library into the cross-platform in-memory
/// repository (no SQLite needed; the curated production set replaces the
/// sample later).
Future<PuzzleRepository> _loadPuzzleRepository() async {
  final json = await rootBundle.loadString(PuzzleSeeder.sampleAsset);
  final puzzles = (jsonDecode(json) as List)
      .cast<Map<String, dynamic>>()
      .map(TacticsPuzzle.fromJson)
      .toList();
  return InMemoryPuzzleRepository(puzzles);
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
