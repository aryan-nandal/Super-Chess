// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_database.dart';

// ignore_for_file: type=lint
class $PuzzlesTable extends Puzzles with TableInfo<$PuzzlesTable, Puzzle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fenMeta = const VerificationMeta('fen');
  @override
  late final GeneratedColumn<String> fen = GeneratedColumn<String>(
    'fen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movesUciMeta = const VerificationMeta(
    'movesUci',
  );
  @override
  late final GeneratedColumn<String> movesUci = GeneratedColumn<String>(
    'moves_uci',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, fen, movesUci, rating];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Puzzle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fen')) {
      context.handle(
        _fenMeta,
        fen.isAcceptableOrUnknown(data['fen']!, _fenMeta),
      );
    } else if (isInserting) {
      context.missing(_fenMeta);
    }
    if (data.containsKey('moves_uci')) {
      context.handle(
        _movesUciMeta,
        movesUci.isAcceptableOrUnknown(data['moves_uci']!, _movesUciMeta),
      );
    } else if (isInserting) {
      context.missing(_movesUciMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Puzzle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Puzzle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fen'],
      )!,
      movesUci: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moves_uci'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
    );
  }

  @override
  $PuzzlesTable createAlias(String alias) {
    return $PuzzlesTable(attachedDatabase, alias);
  }
}

class Puzzle extends DataClass implements Insertable<Puzzle> {
  final String id;
  final String fen;
  final String movesUci;
  final int rating;
  const Puzzle({
    required this.id,
    required this.fen,
    required this.movesUci,
    required this.rating,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fen'] = Variable<String>(fen);
    map['moves_uci'] = Variable<String>(movesUci);
    map['rating'] = Variable<int>(rating);
    return map;
  }

  PuzzlesCompanion toCompanion(bool nullToAbsent) {
    return PuzzlesCompanion(
      id: Value(id),
      fen: Value(fen),
      movesUci: Value(movesUci),
      rating: Value(rating),
    );
  }

  factory Puzzle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Puzzle(
      id: serializer.fromJson<String>(json['id']),
      fen: serializer.fromJson<String>(json['fen']),
      movesUci: serializer.fromJson<String>(json['movesUci']),
      rating: serializer.fromJson<int>(json['rating']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fen': serializer.toJson<String>(fen),
      'movesUci': serializer.toJson<String>(movesUci),
      'rating': serializer.toJson<int>(rating),
    };
  }

  Puzzle copyWith({String? id, String? fen, String? movesUci, int? rating}) =>
      Puzzle(
        id: id ?? this.id,
        fen: fen ?? this.fen,
        movesUci: movesUci ?? this.movesUci,
        rating: rating ?? this.rating,
      );
  Puzzle copyWithCompanion(PuzzlesCompanion data) {
    return Puzzle(
      id: data.id.present ? data.id.value : this.id,
      fen: data.fen.present ? data.fen.value : this.fen,
      movesUci: data.movesUci.present ? data.movesUci.value : this.movesUci,
      rating: data.rating.present ? data.rating.value : this.rating,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Puzzle(')
          ..write('id: $id, ')
          ..write('fen: $fen, ')
          ..write('movesUci: $movesUci, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fen, movesUci, rating);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Puzzle &&
          other.id == this.id &&
          other.fen == this.fen &&
          other.movesUci == this.movesUci &&
          other.rating == this.rating);
}

class PuzzlesCompanion extends UpdateCompanion<Puzzle> {
  final Value<String> id;
  final Value<String> fen;
  final Value<String> movesUci;
  final Value<int> rating;
  final Value<int> rowid;
  const PuzzlesCompanion({
    this.id = const Value.absent(),
    this.fen = const Value.absent(),
    this.movesUci = const Value.absent(),
    this.rating = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzlesCompanion.insert({
    required String id,
    required String fen,
    required String movesUci,
    this.rating = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fen = Value(fen),
       movesUci = Value(movesUci);
  static Insertable<Puzzle> custom({
    Expression<String>? id,
    Expression<String>? fen,
    Expression<String>? movesUci,
    Expression<int>? rating,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fen != null) 'fen': fen,
      if (movesUci != null) 'moves_uci': movesUci,
      if (rating != null) 'rating': rating,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzlesCompanion copyWith({
    Value<String>? id,
    Value<String>? fen,
    Value<String>? movesUci,
    Value<int>? rating,
    Value<int>? rowid,
  }) {
    return PuzzlesCompanion(
      id: id ?? this.id,
      fen: fen ?? this.fen,
      movesUci: movesUci ?? this.movesUci,
      rating: rating ?? this.rating,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fen.present) {
      map['fen'] = Variable<String>(fen.value);
    }
    if (movesUci.present) {
      map['moves_uci'] = Variable<String>(movesUci.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzlesCompanion(')
          ..write('id: $id, ')
          ..write('fen: $fen, ')
          ..write('movesUci: $movesUci, ')
          ..write('rating: $rating, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PuzzleThemesTable extends PuzzleThemes
    with TableInfo<$PuzzleThemesTable, PuzzleTheme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleThemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES puzzles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [puzzleId, theme];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_themes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleTheme> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId, theme};
  @override
  PuzzleTheme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleTheme(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
    );
  }

  @override
  $PuzzleThemesTable createAlias(String alias) {
    return $PuzzleThemesTable(attachedDatabase, alias);
  }
}

class PuzzleTheme extends DataClass implements Insertable<PuzzleTheme> {
  final String puzzleId;
  final String theme;
  const PuzzleTheme({required this.puzzleId, required this.theme});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['theme'] = Variable<String>(theme);
    return map;
  }

  PuzzleThemesCompanion toCompanion(bool nullToAbsent) {
    return PuzzleThemesCompanion(
      puzzleId: Value(puzzleId),
      theme: Value(theme),
    );
  }

  factory PuzzleTheme.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleTheme(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      theme: serializer.fromJson<String>(json['theme']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'theme': serializer.toJson<String>(theme),
    };
  }

  PuzzleTheme copyWith({String? puzzleId, String? theme}) => PuzzleTheme(
    puzzleId: puzzleId ?? this.puzzleId,
    theme: theme ?? this.theme,
  );
  PuzzleTheme copyWithCompanion(PuzzleThemesCompanion data) {
    return PuzzleTheme(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      theme: data.theme.present ? data.theme.value : this.theme,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleTheme(')
          ..write('puzzleId: $puzzleId, ')
          ..write('theme: $theme')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(puzzleId, theme);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleTheme &&
          other.puzzleId == this.puzzleId &&
          other.theme == this.theme);
}

class PuzzleThemesCompanion extends UpdateCompanion<PuzzleTheme> {
  final Value<String> puzzleId;
  final Value<String> theme;
  final Value<int> rowid;
  const PuzzleThemesCompanion({
    this.puzzleId = const Value.absent(),
    this.theme = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzleThemesCompanion.insert({
    required String puzzleId,
    required String theme,
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       theme = Value(theme);
  static Insertable<PuzzleTheme> custom({
    Expression<String>? puzzleId,
    Expression<String>? theme,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (theme != null) 'theme': theme,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzleThemesCompanion copyWith({
    Value<String>? puzzleId,
    Value<String>? theme,
    Value<int>? rowid,
  }) {
    return PuzzleThemesCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      theme: theme ?? this.theme,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleThemesCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('theme: $theme, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentDatabase extends GeneratedDatabase {
  _$ContentDatabase(QueryExecutor e) : super(e);
  $ContentDatabaseManager get managers => $ContentDatabaseManager(this);
  late final $PuzzlesTable puzzles = $PuzzlesTable(this);
  late final $PuzzleThemesTable puzzleThemes = $PuzzleThemesTable(this);
  late final Index idxPuzzleThemesTheme = Index(
    'idx_puzzle_themes_theme',
    'CREATE INDEX idx_puzzle_themes_theme ON puzzle_themes (theme)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    puzzles,
    puzzleThemes,
    idxPuzzleThemesTheme,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'puzzles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('puzzle_themes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PuzzlesTableCreateCompanionBuilder =
    PuzzlesCompanion Function({
      required String id,
      required String fen,
      required String movesUci,
      Value<int> rating,
      Value<int> rowid,
    });
typedef $$PuzzlesTableUpdateCompanionBuilder =
    PuzzlesCompanion Function({
      Value<String> id,
      Value<String> fen,
      Value<String> movesUci,
      Value<int> rating,
      Value<int> rowid,
    });

final class $$PuzzlesTableReferences
    extends BaseReferences<_$ContentDatabase, $PuzzlesTable, Puzzle> {
  $$PuzzlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PuzzleThemesTable, List<PuzzleTheme>>
  _puzzleThemesRefsTable(_$ContentDatabase db) => MultiTypedResultKey.fromTable(
    db.puzzleThemes,
    aliasName: 'puzzles__id__puzzle_themes__puzzle_id',
  );

  $$PuzzleThemesTableProcessedTableManager get puzzleThemesRefs {
    final manager = $$PuzzleThemesTableTableManager(
      $_db,
      $_db.puzzleThemes,
    ).filter((f) => f.puzzleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_puzzleThemesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PuzzlesTableFilterComposer
    extends Composer<_$ContentDatabase, $PuzzlesTable> {
  $$PuzzlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movesUci => $composableBuilder(
    column: $table.movesUci,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> puzzleThemesRefs(
    Expression<bool> Function($$PuzzleThemesTableFilterComposer f) f,
  ) {
    final $$PuzzleThemesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.puzzleThemes,
      getReferencedColumn: (t) => t.puzzleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleThemesTableFilterComposer(
            $db: $db,
            $table: $db.puzzleThemes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PuzzlesTableOrderingComposer
    extends Composer<_$ContentDatabase, $PuzzlesTable> {
  $$PuzzlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fen => $composableBuilder(
    column: $table.fen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movesUci => $composableBuilder(
    column: $table.movesUci,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuzzlesTableAnnotationComposer
    extends Composer<_$ContentDatabase, $PuzzlesTable> {
  $$PuzzlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fen =>
      $composableBuilder(column: $table.fen, builder: (column) => column);

  GeneratedColumn<String> get movesUci =>
      $composableBuilder(column: $table.movesUci, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  Expression<T> puzzleThemesRefs<T extends Object>(
    Expression<T> Function($$PuzzleThemesTableAnnotationComposer a) f,
  ) {
    final $$PuzzleThemesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.puzzleThemes,
      getReferencedColumn: (t) => t.puzzleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzleThemesTableAnnotationComposer(
            $db: $db,
            $table: $db.puzzleThemes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PuzzlesTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $PuzzlesTable,
          Puzzle,
          $$PuzzlesTableFilterComposer,
          $$PuzzlesTableOrderingComposer,
          $$PuzzlesTableAnnotationComposer,
          $$PuzzlesTableCreateCompanionBuilder,
          $$PuzzlesTableUpdateCompanionBuilder,
          (Puzzle, $$PuzzlesTableReferences),
          Puzzle,
          PrefetchHooks Function({bool puzzleThemesRefs})
        > {
  $$PuzzlesTableTableManager(_$ContentDatabase db, $PuzzlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fen = const Value.absent(),
                Value<String> movesUci = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzlesCompanion(
                id: id,
                fen: fen,
                movesUci: movesUci,
                rating: rating,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fen,
                required String movesUci,
                Value<int> rating = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzlesCompanion.insert(
                id: id,
                fen: fen,
                movesUci: movesUci,
                rating: rating,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PuzzlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({puzzleThemesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (puzzleThemesRefs) db.puzzleThemes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (puzzleThemesRefs)
                    await $_getPrefetchedData<
                      Puzzle,
                      $PuzzlesTable,
                      PuzzleTheme
                    >(
                      currentTable: table,
                      referencedTable: $$PuzzlesTableReferences
                          ._puzzleThemesRefsTable(db),
                      managerFromTypedResult: (p0) => $$PuzzlesTableReferences(
                        db,
                        table,
                        p0,
                      ).puzzleThemesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.puzzleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PuzzlesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $PuzzlesTable,
      Puzzle,
      $$PuzzlesTableFilterComposer,
      $$PuzzlesTableOrderingComposer,
      $$PuzzlesTableAnnotationComposer,
      $$PuzzlesTableCreateCompanionBuilder,
      $$PuzzlesTableUpdateCompanionBuilder,
      (Puzzle, $$PuzzlesTableReferences),
      Puzzle,
      PrefetchHooks Function({bool puzzleThemesRefs})
    >;
typedef $$PuzzleThemesTableCreateCompanionBuilder =
    PuzzleThemesCompanion Function({
      required String puzzleId,
      required String theme,
      Value<int> rowid,
    });
typedef $$PuzzleThemesTableUpdateCompanionBuilder =
    PuzzleThemesCompanion Function({
      Value<String> puzzleId,
      Value<String> theme,
      Value<int> rowid,
    });

final class $$PuzzleThemesTableReferences
    extends BaseReferences<_$ContentDatabase, $PuzzleThemesTable, PuzzleTheme> {
  $$PuzzleThemesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PuzzlesTable _puzzleIdTable(_$ContentDatabase db) =>
      db.puzzles.createAlias('puzzle_themes__puzzle_id__puzzles__id');

  $$PuzzlesTableProcessedTableManager get puzzleId {
    final $_column = $_itemColumn<String>('puzzle_id')!;

    final manager = $$PuzzlesTableTableManager(
      $_db,
      $_db.puzzles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_puzzleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PuzzleThemesTableFilterComposer
    extends Composer<_$ContentDatabase, $PuzzleThemesTable> {
  $$PuzzleThemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  $$PuzzlesTableFilterComposer get puzzleId {
    final $$PuzzlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.puzzleId,
      referencedTable: $db.puzzles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzlesTableFilterComposer(
            $db: $db,
            $table: $db.puzzles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleThemesTableOrderingComposer
    extends Composer<_$ContentDatabase, $PuzzleThemesTable> {
  $$PuzzleThemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  $$PuzzlesTableOrderingComposer get puzzleId {
    final $$PuzzlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.puzzleId,
      referencedTable: $db.puzzles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzlesTableOrderingComposer(
            $db: $db,
            $table: $db.puzzles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleThemesTableAnnotationComposer
    extends Composer<_$ContentDatabase, $PuzzleThemesTable> {
  $$PuzzleThemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  $$PuzzlesTableAnnotationComposer get puzzleId {
    final $$PuzzlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.puzzleId,
      referencedTable: $db.puzzles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PuzzlesTableAnnotationComposer(
            $db: $db,
            $table: $db.puzzles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PuzzleThemesTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $PuzzleThemesTable,
          PuzzleTheme,
          $$PuzzleThemesTableFilterComposer,
          $$PuzzleThemesTableOrderingComposer,
          $$PuzzleThemesTableAnnotationComposer,
          $$PuzzleThemesTableCreateCompanionBuilder,
          $$PuzzleThemesTableUpdateCompanionBuilder,
          (PuzzleTheme, $$PuzzleThemesTableReferences),
          PuzzleTheme,
          PrefetchHooks Function({bool puzzleId})
        > {
  $$PuzzleThemesTableTableManager(
    _$ContentDatabase db,
    $PuzzleThemesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleThemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleThemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleThemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleThemesCompanion(
                puzzleId: puzzleId,
                theme: theme,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                required String theme,
                Value<int> rowid = const Value.absent(),
              }) => PuzzleThemesCompanion.insert(
                puzzleId: puzzleId,
                theme: theme,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PuzzleThemesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({puzzleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (puzzleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.puzzleId,
                                referencedTable: $$PuzzleThemesTableReferences
                                    ._puzzleIdTable(db),
                                referencedColumn: $$PuzzleThemesTableReferences
                                    ._puzzleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PuzzleThemesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $PuzzleThemesTable,
      PuzzleTheme,
      $$PuzzleThemesTableFilterComposer,
      $$PuzzleThemesTableOrderingComposer,
      $$PuzzleThemesTableAnnotationComposer,
      $$PuzzleThemesTableCreateCompanionBuilder,
      $$PuzzleThemesTableUpdateCompanionBuilder,
      (PuzzleTheme, $$PuzzleThemesTableReferences),
      PuzzleTheme,
      PrefetchHooks Function({bool puzzleId})
    >;

class $ContentDatabaseManager {
  final _$ContentDatabase _db;
  $ContentDatabaseManager(this._db);
  $$PuzzlesTableTableManager get puzzles =>
      $$PuzzlesTableTableManager(_db, _db.puzzles);
  $$PuzzleThemesTableTableManager get puzzleThemes =>
      $$PuzzleThemesTableTableManager(_db, _db.puzzleThemes);
}
