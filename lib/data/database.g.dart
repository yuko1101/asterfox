// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
      'scope', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [scope, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
          _scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope, key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      scope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String scope;
  final String key;
  final String value;
  const SettingsEntry(
      {required this.scope, required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      scope: Value(scope),
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingsEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      scope: serializer.fromJson<String>(json['scope']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsEntry copyWith({String? scope, String? key, String? value}) =>
      SettingsEntry(
        scope: scope ?? this.scope,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      scope: data.scope.present ? data.scope.value : this.scope,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('scope: $scope, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scope, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.scope == this.scope &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> scope;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.scope = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String scope,
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : scope = Value(scope),
        key = Value(key),
        value = Value(value);
  static Insertable<SettingsEntry> custom({
    Expression<String>? scope,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith(
      {Value<String>? scope,
      Value<String>? key,
      Value<String>? value,
      Value<int>? rowid}) {
    return SettingsEntriesCompanion(
      scope: scope ?? this.scope,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('scope: $scope, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
      'scope', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [scope, id, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(Insertable<Document> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
          _scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope, id};
  @override
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      scope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class Document extends DataClass implements Insertable<Document> {
  final String scope;
  final String id;
  final String json;
  const Document({required this.scope, required this.id, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      scope: Value(scope),
      id: Value(id),
      json: Value(json),
    );
  }

  factory Document.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      scope: serializer.fromJson<String>(json['scope']),
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
    };
  }

  Document copyWith({String? scope, String? id, String? json}) => Document(
        scope: scope ?? this.scope,
        id: id ?? this.id,
        json: json ?? this.json,
      );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      scope: data.scope.present ? data.scope.value : this.scope,
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('scope: $scope, ')
          ..write('id: $id, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scope, id, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.scope == this.scope &&
          other.id == this.id &&
          other.json == this.json);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<String> scope;
  final Value<String> id;
  final Value<String> json;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.scope = const Value.absent(),
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String scope,
    required String id,
    required String json,
    this.rowid = const Value.absent(),
  })  : scope = Value(scope),
        id = Value(id),
        json = Value(json);
  static Insertable<Document> custom({
    Expression<String>? scope,
    Expression<String>? id,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith(
      {Value<String>? scope,
      Value<String>? id,
      Value<String>? json,
      Value<int>? rowid}) {
    return DocumentsCompanion(
      scope: scope ?? this.scope,
      id: id ?? this.id,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('scope: $scope, ')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsEntriesTable settingsEntries =
      $SettingsEntriesTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [settingsEntries, documents];
}

typedef $$SettingsEntriesTableCreateCompanionBuilder = SettingsEntriesCompanion
    Function({
  required String scope,
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsEntriesTableUpdateCompanionBuilder = SettingsEntriesCompanion
    Function({
  Value<String> scope,
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsEntriesTable,
    SettingsEntry,
    $$SettingsEntriesTableFilterComposer,
    $$SettingsEntriesTableOrderingComposer,
    $$SettingsEntriesTableAnnotationComposer,
    $$SettingsEntriesTableCreateCompanionBuilder,
    $$SettingsEntriesTableUpdateCompanionBuilder,
    (
      SettingsEntry,
      BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>
    ),
    SettingsEntry,
    PrefetchHooks Function()> {
  $$SettingsEntriesTableTableManager(
      _$AppDatabase db, $SettingsEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> scope = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsEntriesCompanion(
            scope: scope,
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String scope,
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsEntriesCompanion.insert(
            scope: scope,
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsEntriesTable,
    SettingsEntry,
    $$SettingsEntriesTableFilterComposer,
    $$SettingsEntriesTableOrderingComposer,
    $$SettingsEntriesTableAnnotationComposer,
    $$SettingsEntriesTableCreateCompanionBuilder,
    $$SettingsEntriesTableUpdateCompanionBuilder,
    (
      SettingsEntry,
      BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>
    ),
    SettingsEntry,
    PrefetchHooks Function()>;
typedef $$DocumentsTableCreateCompanionBuilder = DocumentsCompanion Function({
  required String scope,
  required String id,
  required String json,
  Value<int> rowid,
});
typedef $$DocumentsTableUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<String> scope,
  Value<String> id,
  Value<String> json,
  Value<int> rowid,
});

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$DocumentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (Document, BaseReferences<_$AppDatabase, $DocumentsTable, Document>),
    Document,
    PrefetchHooks Function()> {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> scope = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion(
            scope: scope,
            id: id,
            json: json,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String scope,
            required String id,
            required String json,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion.insert(
            scope: scope,
            id: id,
            json: json,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (Document, BaseReferences<_$AppDatabase, $DocumentsTable, Document>),
    Document,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
}
