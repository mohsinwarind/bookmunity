// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UNKNOWN'),
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _bookKeyMeta = const VerificationMeta(
    'bookKey',
  );
  @override
  late final GeneratedColumn<String> bookKey = GeneratedColumn<String>(
    'book_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _shelfMeta = const VerificationMeta('shelf');
  @override
  late final GeneratedColumn<String> shelf = GeneratedColumn<String>(
    'shelf',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('wantToRead'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCfiMeta = const VerificationMeta(
    'lastCfi',
  );
  @override
  late final GeneratedColumn<String> lastCfi = GeneratedColumn<String>(
    'last_cfi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressPercentMeta = const VerificationMeta(
    'progressPercent',
  );
  @override
  late final GeneratedColumn<double> progressPercent = GeneratedColumn<double>(
    'progress_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalLocationsMeta = const VerificationMeta(
    'totalLocations',
  );
  @override
  late final GeneratedColumn<int> totalLocations = GeneratedColumn<int>(
    'total_locations',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFinishedMeta = const VerificationMeta(
    'isFinished',
  );
  @override
  late final GeneratedColumn<bool> isFinished = GeneratedColumn<bool>(
    'is_finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_finished" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    coverPath,
    filePath,
    fileHash,
    bookKey,
    shelf,
    addedAt,
    lastOpenedAt,
    lastCfi,
    progressPercent,
    totalLocations,
    isFinished,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('book_key')) {
      context.handle(
        _bookKeyMeta,
        bookKey.isAcceptableOrUnknown(data['book_key']!, _bookKeyMeta),
      );
    }
    if (data.containsKey('shelf')) {
      context.handle(
        _shelfMeta,
        shelf.isAcceptableOrUnknown(data['shelf']!, _shelfMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_cfi')) {
      context.handle(
        _lastCfiMeta,
        lastCfi.isAcceptableOrUnknown(data['last_cfi']!, _lastCfiMeta),
      );
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
        _progressPercentMeta,
        progressPercent.isAcceptableOrUnknown(
          data['progress_percent']!,
          _progressPercentMeta,
        ),
      );
    }
    if (data.containsKey('total_locations')) {
      context.handle(
        _totalLocationsMeta,
        totalLocations.isAcceptableOrUnknown(
          data['total_locations']!,
          _totalLocationsMeta,
        ),
      );
    }
    if (data.containsKey('is_finished')) {
      context.handle(
        _isFinishedMeta,
        isFinished.isAcceptableOrUnknown(data['is_finished']!, _isFinishedMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      bookKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_key'],
      )!,
      shelf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      lastCfi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_cfi'],
      ),
      progressPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_percent'],
      )!,
      totalLocations: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_locations'],
      ),
      isFinished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_finished'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  final int id;
  final String title;
  final String author;
  final String? coverPath;
  final String filePath;
  final String fileHash;
  final String bookKey;
  final String shelf;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final String? lastCfi;
  final double progressPercent;
  final int? totalLocations;
  final bool isFinished;
  final DateTime? finishedAt;
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverPath,
    required this.filePath,
    required this.fileHash,
    required this.bookKey,
    required this.shelf,
    required this.addedAt,
    this.lastOpenedAt,
    this.lastCfi,
    required this.progressPercent,
    this.totalLocations,
    required this.isFinished,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['file_path'] = Variable<String>(filePath);
    map['file_hash'] = Variable<String>(fileHash);
    map['book_key'] = Variable<String>(bookKey);
    map['shelf'] = Variable<String>(shelf);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    if (!nullToAbsent || lastCfi != null) {
      map['last_cfi'] = Variable<String>(lastCfi);
    }
    map['progress_percent'] = Variable<double>(progressPercent);
    if (!nullToAbsent || totalLocations != null) {
      map['total_locations'] = Variable<int>(totalLocations);
    }
    map['is_finished'] = Variable<bool>(isFinished);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      filePath: Value(filePath),
      fileHash: Value(fileHash),
      bookKey: Value(bookKey),
      shelf: Value(shelf),
      addedAt: Value(addedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      lastCfi: lastCfi == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCfi),
      progressPercent: Value(progressPercent),
      totalLocations: totalLocations == null && nullToAbsent
          ? const Value.absent()
          : Value(totalLocations),
      isFinished: Value(isFinished),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      bookKey: serializer.fromJson<String>(json['bookKey']),
      shelf: serializer.fromJson<String>(json['shelf']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      lastCfi: serializer.fromJson<String?>(json['lastCfi']),
      progressPercent: serializer.fromJson<double>(json['progressPercent']),
      totalLocations: serializer.fromJson<int?>(json['totalLocations']),
      isFinished: serializer.fromJson<bool>(json['isFinished']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'coverPath': serializer.toJson<String?>(coverPath),
      'filePath': serializer.toJson<String>(filePath),
      'fileHash': serializer.toJson<String>(fileHash),
      'bookKey': serializer.toJson<String>(bookKey),
      'shelf': serializer.toJson<String>(shelf),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'lastCfi': serializer.toJson<String?>(lastCfi),
      'progressPercent': serializer.toJson<double>(progressPercent),
      'totalLocations': serializer.toJson<int?>(totalLocations),
      'isFinished': serializer.toJson<bool>(isFinished),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  Book copyWith({
    int? id,
    String? title,
    String? author,
    Value<String?> coverPath = const Value.absent(),
    String? filePath,
    String? fileHash,
    String? bookKey,
    String? shelf,
    DateTime? addedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    Value<String?> lastCfi = const Value.absent(),
    double? progressPercent,
    Value<int?> totalLocations = const Value.absent(),
    bool? isFinished,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => Book(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    filePath: filePath ?? this.filePath,
    fileHash: fileHash ?? this.fileHash,
    bookKey: bookKey ?? this.bookKey,
    shelf: shelf ?? this.shelf,
    addedAt: addedAt ?? this.addedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    lastCfi: lastCfi.present ? lastCfi.value : this.lastCfi,
    progressPercent: progressPercent ?? this.progressPercent,
    totalLocations: totalLocations.present
        ? totalLocations.value
        : this.totalLocations,
    isFinished: isFinished ?? this.isFinished,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      bookKey: data.bookKey.present ? data.bookKey.value : this.bookKey,
      shelf: data.shelf.present ? data.shelf.value : this.shelf,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      lastCfi: data.lastCfi.present ? data.lastCfi.value : this.lastCfi,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      totalLocations: data.totalLocations.present
          ? data.totalLocations.value
          : this.totalLocations,
      isFinished: data.isFinished.present
          ? data.isFinished.value
          : this.isFinished,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverPath: $coverPath, ')
          ..write('filePath: $filePath, ')
          ..write('fileHash: $fileHash, ')
          ..write('bookKey: $bookKey, ')
          ..write('shelf: $shelf, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('lastCfi: $lastCfi, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('totalLocations: $totalLocations, ')
          ..write('isFinished: $isFinished, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    coverPath,
    filePath,
    fileHash,
    bookKey,
    shelf,
    addedAt,
    lastOpenedAt,
    lastCfi,
    progressPercent,
    totalLocations,
    isFinished,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.coverPath == this.coverPath &&
          other.filePath == this.filePath &&
          other.fileHash == this.fileHash &&
          other.bookKey == this.bookKey &&
          other.shelf == this.shelf &&
          other.addedAt == this.addedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.lastCfi == this.lastCfi &&
          other.progressPercent == this.progressPercent &&
          other.totalLocations == this.totalLocations &&
          other.isFinished == this.isFinished &&
          other.finishedAt == this.finishedAt);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> author;
  final Value<String?> coverPath;
  final Value<String> filePath;
  final Value<String> fileHash;
  final Value<String> bookKey;
  final Value<String> shelf;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<String?> lastCfi;
  final Value<double> progressPercent;
  final Value<int?> totalLocations;
  final Value<bool> isFinished;
  final Value<DateTime?> finishedAt;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.bookKey = const Value.absent(),
    this.shelf = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.lastCfi = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.totalLocations = const Value.absent(),
    this.isFinished = const Value.absent(),
    this.finishedAt = const Value.absent(),
  });
  BooksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.author = const Value.absent(),
    this.coverPath = const Value.absent(),
    required String filePath,
    required String fileHash,
    this.bookKey = const Value.absent(),
    this.shelf = const Value.absent(),
    required DateTime addedAt,
    this.lastOpenedAt = const Value.absent(),
    this.lastCfi = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.totalLocations = const Value.absent(),
    this.isFinished = const Value.absent(),
    this.finishedAt = const Value.absent(),
  }) : title = Value(title),
       filePath = Value(filePath),
       fileHash = Value(fileHash),
       addedAt = Value(addedAt);
  static Insertable<Book> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? coverPath,
    Expression<String>? filePath,
    Expression<String>? fileHash,
    Expression<String>? bookKey,
    Expression<String>? shelf,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<String>? lastCfi,
    Expression<double>? progressPercent,
    Expression<int>? totalLocations,
    Expression<bool>? isFinished,
    Expression<DateTime>? finishedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverPath != null) 'cover_path': coverPath,
      if (filePath != null) 'file_path': filePath,
      if (fileHash != null) 'file_hash': fileHash,
      if (bookKey != null) 'book_key': bookKey,
      if (shelf != null) 'shelf': shelf,
      if (addedAt != null) 'added_at': addedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (lastCfi != null) 'last_cfi': lastCfi,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (totalLocations != null) 'total_locations': totalLocations,
      if (isFinished != null) 'is_finished': isFinished,
      if (finishedAt != null) 'finished_at': finishedAt,
    });
  }

  BooksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? author,
    Value<String?>? coverPath,
    Value<String>? filePath,
    Value<String>? fileHash,
    Value<String>? bookKey,
    Value<String>? shelf,
    Value<DateTime>? addedAt,
    Value<DateTime?>? lastOpenedAt,
    Value<String?>? lastCfi,
    Value<double>? progressPercent,
    Value<int?>? totalLocations,
    Value<bool>? isFinished,
    Value<DateTime?>? finishedAt,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      filePath: filePath ?? this.filePath,
      fileHash: fileHash ?? this.fileHash,
      bookKey: bookKey ?? this.bookKey,
      shelf: shelf ?? this.shelf,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastCfi: lastCfi ?? this.lastCfi,
      progressPercent: progressPercent ?? this.progressPercent,
      totalLocations: totalLocations ?? this.totalLocations,
      isFinished: isFinished ?? this.isFinished,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (bookKey.present) {
      map['book_key'] = Variable<String>(bookKey.value);
    }
    if (shelf.present) {
      map['shelf'] = Variable<String>(shelf.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (lastCfi.present) {
      map['last_cfi'] = Variable<String>(lastCfi.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<double>(progressPercent.value);
    }
    if (totalLocations.present) {
      map['total_locations'] = Variable<int>(totalLocations.value);
    }
    if (isFinished.present) {
      map['is_finished'] = Variable<bool>(isFinished.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverPath: $coverPath, ')
          ..write('filePath: $filePath, ')
          ..write('fileHash: $fileHash, ')
          ..write('bookKey: $bookKey, ')
          ..write('shelf: $shelf, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('lastCfi: $lastCfi, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('totalLocations: $totalLocations, ')
          ..write('isFinished: $isFinished, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }
}

class $HighlightsTable extends Highlights
    with TableInfo<$HighlightsTable, Highlight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cfiRangeMeta = const VerificationMeta(
    'cfiRange',
  );
  @override
  late final GeneratedColumn<String> cfiRange = GeneratedColumn<String>(
    'cfi_range',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedTextMeta = const VerificationMeta(
    'selectedText',
  );
  @override
  late final GeneratedColumn<String> selectedText = GeneratedColumn<String>(
    'selected_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterTitleMeta = const VerificationMeta(
    'chapterTitle',
  );
  @override
  late final GeneratedColumn<String> chapterTitle = GeneratedColumn<String>(
    'chapter_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    cfiRange,
    selectedText,
    color,
    note,
    chapterTitle,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<Highlight> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('cfi_range')) {
      context.handle(
        _cfiRangeMeta,
        cfiRange.isAcceptableOrUnknown(data['cfi_range']!, _cfiRangeMeta),
      );
    } else if (isInserting) {
      context.missing(_cfiRangeMeta);
    }
    if (data.containsKey('selected_text')) {
      context.handle(
        _selectedTextMeta,
        selectedText.isAcceptableOrUnknown(
          data['selected_text']!,
          _selectedTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedTextMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('chapter_title')) {
      context.handle(
        _chapterTitleMeta,
        chapterTitle.isAcceptableOrUnknown(
          data['chapter_title']!,
          _chapterTitleMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Highlight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Highlight(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      cfiRange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cfi_range'],
      )!,
      selectedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_text'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      chapterTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_title'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HighlightsTable createAlias(String alias) {
    return $HighlightsTable(attachedDatabase, alias);
  }
}

class Highlight extends DataClass implements Insertable<Highlight> {
  final int id;
  final int bookId;
  final String cfiRange;
  final String selectedText;
  final int color;
  final String? note;
  final String? chapterTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Highlight({
    required this.id,
    required this.bookId,
    required this.cfiRange,
    required this.selectedText,
    required this.color,
    this.note,
    this.chapterTitle,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['cfi_range'] = Variable<String>(cfiRange);
    map['selected_text'] = Variable<String>(selectedText);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || chapterTitle != null) {
      map['chapter_title'] = Variable<String>(chapterTitle);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HighlightsCompanion toCompanion(bool nullToAbsent) {
    return HighlightsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      cfiRange: Value(cfiRange),
      selectedText: Value(selectedText),
      color: Value(color),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      chapterTitle: chapterTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterTitle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Highlight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Highlight(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      cfiRange: serializer.fromJson<String>(json['cfiRange']),
      selectedText: serializer.fromJson<String>(json['selectedText']),
      color: serializer.fromJson<int>(json['color']),
      note: serializer.fromJson<String?>(json['note']),
      chapterTitle: serializer.fromJson<String?>(json['chapterTitle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'cfiRange': serializer.toJson<String>(cfiRange),
      'selectedText': serializer.toJson<String>(selectedText),
      'color': serializer.toJson<int>(color),
      'note': serializer.toJson<String?>(note),
      'chapterTitle': serializer.toJson<String?>(chapterTitle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Highlight copyWith({
    int? id,
    int? bookId,
    String? cfiRange,
    String? selectedText,
    int? color,
    Value<String?> note = const Value.absent(),
    Value<String?> chapterTitle = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Highlight(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    cfiRange: cfiRange ?? this.cfiRange,
    selectedText: selectedText ?? this.selectedText,
    color: color ?? this.color,
    note: note.present ? note.value : this.note,
    chapterTitle: chapterTitle.present ? chapterTitle.value : this.chapterTitle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Highlight copyWithCompanion(HighlightsCompanion data) {
    return Highlight(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      cfiRange: data.cfiRange.present ? data.cfiRange.value : this.cfiRange,
      selectedText: data.selectedText.present
          ? data.selectedText.value
          : this.selectedText,
      color: data.color.present ? data.color.value : this.color,
      note: data.note.present ? data.note.value : this.note,
      chapterTitle: data.chapterTitle.present
          ? data.chapterTitle.value
          : this.chapterTitle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Highlight(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('cfiRange: $cfiRange, ')
          ..write('selectedText: $selectedText, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('chapterTitle: $chapterTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    cfiRange,
    selectedText,
    color,
    note,
    chapterTitle,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Highlight &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.cfiRange == this.cfiRange &&
          other.selectedText == this.selectedText &&
          other.color == this.color &&
          other.note == this.note &&
          other.chapterTitle == this.chapterTitle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HighlightsCompanion extends UpdateCompanion<Highlight> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<String> cfiRange;
  final Value<String> selectedText;
  final Value<int> color;
  final Value<String?> note;
  final Value<String?> chapterTitle;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const HighlightsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.cfiRange = const Value.absent(),
    this.selectedText = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.chapterTitle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HighlightsCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required String cfiRange,
    required String selectedText,
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.chapterTitle = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : bookId = Value(bookId),
       cfiRange = Value(cfiRange),
       selectedText = Value(selectedText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Highlight> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? cfiRange,
    Expression<String>? selectedText,
    Expression<int>? color,
    Expression<String>? note,
    Expression<String>? chapterTitle,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (cfiRange != null) 'cfi_range': cfiRange,
      if (selectedText != null) 'selected_text': selectedText,
      if (color != null) 'color': color,
      if (note != null) 'note': note,
      if (chapterTitle != null) 'chapter_title': chapterTitle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HighlightsCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<String>? cfiRange,
    Value<String>? selectedText,
    Value<int>? color,
    Value<String?>? note,
    Value<String?>? chapterTitle,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return HighlightsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      cfiRange: cfiRange ?? this.cfiRange,
      selectedText: selectedText ?? this.selectedText,
      color: color ?? this.color,
      note: note ?? this.note,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (cfiRange.present) {
      map['cfi_range'] = Variable<String>(cfiRange.value);
    }
    if (selectedText.present) {
      map['selected_text'] = Variable<String>(selectedText.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (chapterTitle.present) {
      map['chapter_title'] = Variable<String>(chapterTitle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HighlightsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('cfiRange: $cfiRange, ')
          ..write('selectedText: $selectedText, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('chapterTitle: $chapterTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DictionaryCachesTable extends DictionaryCaches
    with TableInfo<$DictionaryCachesTable, DictionaryCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [word, responseJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word};
  @override
  DictionaryCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryCache(
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $DictionaryCachesTable createAlias(String alias) {
    return $DictionaryCachesTable(attachedDatabase, alias);
  }
}

class DictionaryCache extends DataClass implements Insertable<DictionaryCache> {
  final String word;
  final String responseJson;
  final DateTime cachedAt;
  const DictionaryCache({
    required this.word,
    required this.responseJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    map['response_json'] = Variable<String>(responseJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  DictionaryCachesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryCachesCompanion(
      word: Value(word),
      responseJson: Value(responseJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory DictionaryCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryCache(
      word: serializer.fromJson<String>(json['word']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'responseJson': serializer.toJson<String>(responseJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  DictionaryCache copyWith({
    String? word,
    String? responseJson,
    DateTime? cachedAt,
  }) => DictionaryCache(
    word: word ?? this.word,
    responseJson: responseJson ?? this.responseJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  DictionaryCache copyWithCompanion(DictionaryCachesCompanion data) {
    return DictionaryCache(
      word: data.word.present ? data.word.value : this.word,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryCache(')
          ..write('word: $word, ')
          ..write('responseJson: $responseJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(word, responseJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryCache &&
          other.word == this.word &&
          other.responseJson == this.responseJson &&
          other.cachedAt == this.cachedAt);
}

class DictionaryCachesCompanion extends UpdateCompanion<DictionaryCache> {
  final Value<String> word;
  final Value<String> responseJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const DictionaryCachesCompanion({
    this.word = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictionaryCachesCompanion.insert({
    required String word,
    required String responseJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : word = Value(word),
       responseJson = Value(responseJson),
       cachedAt = Value(cachedAt);
  static Insertable<DictionaryCache> custom({
    Expression<String>? word,
    Expression<String>? responseJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (responseJson != null) 'response_json': responseJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictionaryCachesCompanion copyWith({
    Value<String>? word,
    Value<String>? responseJson,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return DictionaryCachesCompanion(
      word: word ?? this.word,
      responseJson: responseJson ?? this.responseJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryCachesCompanion(')
          ..write('word: $word, ')
          ..write('responseJson: $responseJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $HighlightsTable highlights = $HighlightsTable(this);
  late final $DictionaryCachesTable dictionaryCaches = $DictionaryCachesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    highlights,
    dictionaryCaches,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('highlights', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  required String title,
  Value<String> author,
  Value<String?> coverPath,
  required String filePath,
  required String fileHash,
  Value<String> bookKey,
  Value<String> shelf,
  required DateTime addedAt,
  Value<DateTime?> lastOpenedAt,
  Value<String?> lastCfi,
  Value<double> progressPercent,
  Value<int?> totalLocations,
  Value<bool> isFinished,
  Value<DateTime?> finishedAt,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> author,
  Value<String?> coverPath,
  Value<String> filePath,
  Value<String> fileHash,
  Value<String> bookKey,
  Value<String> shelf,
  Value<DateTime> addedAt,
  Value<DateTime?> lastOpenedAt,
  Value<String?> lastCfi,
  Value<double> progressPercent,
  Value<int?> totalLocations,
  Value<bool> isFinished,
  Value<DateTime?> finishedAt,
});

final class $$BooksTableReferences
    extends BaseReferences<_$AppDatabase, $BooksTable, Book> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HighlightsTable, List<Highlight>>
  _highlightsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.highlights,
    aliasName: 'books__id__highlights__book_id',
  );

  $$HighlightsTableProcessedTableManager get highlightsRefs {
    final manager = $$HighlightsTableTableManager(
      $_db,
      $_db.highlights,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_highlightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookKey => $composableBuilder(
    column: $table.bookKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shelf => $composableBuilder(
    column: $table.shelf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCfi => $composableBuilder(
    column: $table.lastCfi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalLocations => $composableBuilder(
    column: $table.totalLocations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> highlightsRefs(
    Expression<bool> Function($$HighlightsTableFilterComposer f) f,
  ) {
    final $$HighlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.highlights,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HighlightsTableFilterComposer(
            $db: $db,
            $table: $db.highlights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookKey => $composableBuilder(
    column: $table.bookKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shelf => $composableBuilder(
    column: $table.shelf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCfi => $composableBuilder(
    column: $table.lastCfi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalLocations => $composableBuilder(
    column: $table.totalLocations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<String> get bookKey =>
      $composableBuilder(column: $table.bookKey, builder: (column) => column);

  GeneratedColumn<String> get shelf =>
      $composableBuilder(column: $table.shelf, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCfi =>
      $composableBuilder(column: $table.lastCfi, builder: (column) => column);

  GeneratedColumn<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalLocations => $composableBuilder(
    column: $table.totalLocations,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  Expression<T> highlightsRefs<T extends Object>(
    Expression<T> Function($$HighlightsTableAnnotationComposer a) f,
  ) {
    final $$HighlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.highlights,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HighlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.highlights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, $$BooksTableReferences),
          Book,
          PrefetchHooks Function({bool highlightsRefs})
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<String> bookKey = const Value.absent(),
                Value<String> shelf = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<String?> lastCfi = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<int?> totalLocations = const Value.absent(),
                Value<bool> isFinished = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                title: title,
                author: author,
                coverPath: coverPath,
                filePath: filePath,
                fileHash: fileHash,
                bookKey: bookKey,
                shelf: shelf,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                lastCfi: lastCfi,
                progressPercent: progressPercent,
                totalLocations: totalLocations,
                isFinished: isFinished,
                finishedAt: finishedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String> author = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                required String filePath,
                required String fileHash,
                Value<String> bookKey = const Value.absent(),
                Value<String> shelf = const Value.absent(),
                required DateTime addedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<String?> lastCfi = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<int?> totalLocations = const Value.absent(),
                Value<bool> isFinished = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                title: title,
                author: author,
                coverPath: coverPath,
                filePath: filePath,
                fileHash: fileHash,
                bookKey: bookKey,
                shelf: shelf,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                lastCfi: lastCfi,
                progressPercent: progressPercent,
                totalLocations: totalLocations,
                isFinished: isFinished,
                finishedAt: finishedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, Book>(table),
                  $$BooksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({highlightsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (highlightsRefs) db.highlights],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (highlightsRefs)
                    await $_getPrefetchedDataByColumns<
                      Book,
                      $BooksTable,
                      Highlight,
                      $HighlightsTable
                    >(
                      currentTable: table,
                      referencedTable: $$BooksTableReferences
                          ._highlightsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BooksTableReferences(db, table, p0).highlightsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'book_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, $$BooksTableReferences),
      Book,
      PrefetchHooks Function({bool highlightsRefs})
    >;
typedef $$HighlightsTableCreateCompanionBuilder = HighlightsCompanion Function({
  Value<int> id,
  required int bookId,
  required String cfiRange,
  required String selectedText,
  Value<int> color,
  Value<String?> note,
  Value<String?> chapterTitle,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$HighlightsTableUpdateCompanionBuilder = HighlightsCompanion Function({
  Value<int> id,
  Value<int> bookId,
  Value<String> cfiRange,
  Value<String> selectedText,
  Value<int> color,
  Value<String?> note,
  Value<String?> chapterTitle,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$HighlightsTableReferences
    extends BaseReferences<_$AppDatabase, $HighlightsTable, Highlight> {
  $$HighlightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('highlights__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HighlightsTableFilterComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cfiRange => $composableBuilder(
    column: $table.cfiRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HighlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cfiRange => $composableBuilder(
    column: $table.cfiRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HighlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cfiRange =>
      $composableBuilder(column: $table.cfiRange, builder: (column) => column);

  GeneratedColumn<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get chapterTitle => $composableBuilder(
    column: $table.chapterTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HighlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HighlightsTable,
          Highlight,
          $$HighlightsTableFilterComposer,
          $$HighlightsTableOrderingComposer,
          $$HighlightsTableAnnotationComposer,
          $$HighlightsTableCreateCompanionBuilder,
          $$HighlightsTableUpdateCompanionBuilder,
          (Highlight, $$HighlightsTableReferences),
          Highlight,
          PrefetchHooks Function({bool bookId})
        > {
  $$HighlightsTableTableManager(_$AppDatabase db, $HighlightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HighlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HighlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HighlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> cfiRange = const Value.absent(),
                Value<String> selectedText = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> chapterTitle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HighlightsCompanion(
                id: id,
                bookId: bookId,
                cfiRange: cfiRange,
                selectedText: selectedText,
                color: color,
                note: note,
                chapterTitle: chapterTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required String cfiRange,
                required String selectedText,
                Value<int> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> chapterTitle = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => HighlightsCompanion.insert(
                id: id,
                bookId: bookId,
                cfiRange: cfiRange,
                selectedText: selectedText,
                color: color,
                note: note,
                chapterTitle: chapterTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HighlightsTable, Highlight>(table),
                  $$HighlightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
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
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$HighlightsTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$HighlightsTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
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

typedef $$HighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HighlightsTable,
      Highlight,
      $$HighlightsTableFilterComposer,
      $$HighlightsTableOrderingComposer,
      $$HighlightsTableAnnotationComposer,
      $$HighlightsTableCreateCompanionBuilder,
      $$HighlightsTableUpdateCompanionBuilder,
      (Highlight, $$HighlightsTableReferences),
      Highlight,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$DictionaryCachesTableCreateCompanionBuilder =
    DictionaryCachesCompanion Function({
      required String word,
      required String responseJson,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$DictionaryCachesTableUpdateCompanionBuilder =
    DictionaryCachesCompanion Function({
      Value<String> word,
      Value<String> responseJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$DictionaryCachesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryCachesTable> {
  $$DictionaryCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryCachesTable> {
  $$DictionaryCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryCachesTable> {
  $$DictionaryCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$DictionaryCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryCachesTable,
          DictionaryCache,
          $$DictionaryCachesTableFilterComposer,
          $$DictionaryCachesTableOrderingComposer,
          $$DictionaryCachesTableAnnotationComposer,
          $$DictionaryCachesTableCreateCompanionBuilder,
          $$DictionaryCachesTableUpdateCompanionBuilder,
          (
            DictionaryCache,
            BaseReferences<
              _$AppDatabase,
              $DictionaryCachesTable,
              DictionaryCache
            >,
          ),
          DictionaryCache,
          PrefetchHooks Function()
        > {
  $$DictionaryCachesTableTableManager(
    _$AppDatabase db,
    $DictionaryCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionaryCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<String> responseJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionaryCachesCompanion(
                word: word,
                responseJson: responseJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                required String responseJson,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => DictionaryCachesCompanion.insert(
                word: word,
                responseJson: responseJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DictionaryCachesTable, DictionaryCache>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DictionaryCachesTable,
                    DictionaryCache
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryCachesTable,
      DictionaryCache,
      $$DictionaryCachesTableFilterComposer,
      $$DictionaryCachesTableOrderingComposer,
      $$DictionaryCachesTableAnnotationComposer,
      $$DictionaryCachesTableCreateCompanionBuilder,
      $$DictionaryCachesTableUpdateCompanionBuilder,
      (
        DictionaryCache,
        BaseReferences<_$AppDatabase, $DictionaryCachesTable, DictionaryCache>,
      ),
      DictionaryCache,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$HighlightsTableTableManager get highlights =>
      $$HighlightsTableTableManager(_db, _db.highlights);
  $$DictionaryCachesTableTableManager get dictionaryCaches =>
      $$DictionaryCachesTableTableManager(_db, _db.dictionaryCaches);
}
