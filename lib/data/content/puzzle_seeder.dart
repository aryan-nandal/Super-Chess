import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../domain/tactics/tactics.dart';
import 'content_database.dart';

/// Seeds the read-only [ContentDatabase] with the bundled puzzle library.
///
/// In production the curated JSON (produced by `tool/curate_puzzles.dart` from
/// the CC0 Lichess DB) is bundled as an asset and loaded once. Seeding is
/// idempotent — it no-ops when the library is already populated.
class PuzzleSeeder {
  static const defaultAsset = 'assets/puzzles/sample_puzzles.json';

  final ContentDatabase db;

  PuzzleSeeder(this.db);

  /// Loads [assetPath] via [bundle] (defaults to [rootBundle]) and seeds it.
  Future<int> seedFromAsset({
    AssetBundle? bundle,
    String assetPath = defaultAsset,
  }) async {
    final json = await (bundle ?? rootBundle).loadString(assetPath);
    return seedFromJson(json);
  }

  /// Seeds from a decoded JSON array of puzzles. Returns the number inserted
  /// (0 if the library was already populated).
  Future<int> seedFromJson(String json) async {
    if (await _isPopulated()) return 0;

    final puzzles = (jsonDecode(json) as List)
        .cast<Map<String, dynamic>>()
        .map(TacticsPuzzle.fromJson)
        .toList();

    await db.batch((batch) {
      for (final p in puzzles) {
        batch.insert(
          db.puzzles,
          PuzzlesCompanion.insert(
            id: p.id,
            fen: p.fen,
            movesUci: p.solution.join(' '),
            rating: Value(p.rating),
          ),
          mode: InsertMode.insertOrReplace,
        );
        for (final theme in p.themes) {
          batch.insert(
            db.puzzleThemes,
            PuzzleThemesCompanion.insert(puzzleId: p.id, theme: theme),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
    return puzzles.length;
  }

  Future<bool> _isPopulated() async {
    final count = db.puzzles.id.count();
    final row =
        await (db.selectOnly(db.puzzles)..addColumns([count])).getSingle();
    return (row.read(count) ?? 0) > 0;
  }
}
