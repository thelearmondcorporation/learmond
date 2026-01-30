import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

/* =========================
   PLATFORM HELPERS
   ========================= */

String _bin(String name) {
  if (Platform.isWindows) {
    return '$name.exe';
  }
  return name;
}

Future<ProcessResult> _run(
  String command,
  List<String> args, {
  bool inheritStdio = false,
}) async {
  if (inheritStdio) {
    final p = await Process.start(
      command,
      args,
      runInShell: true,
    );
    await stdout.addStream(p.stdout);
    await stderr.addStream(p.stderr);
    final code = await p.exitCode;
    return ProcessResult(p.pid, code, null, null);
  }

  return Process.run(
    command,
    args,
    runInShell: true,
  );
}

String? _pgDataDir() {
  return Platform.environment['PGDATA'];
}

class PostgresCommand extends Command {
  @override
  final name = 'postgres';

  @override
  final description = 'Manage local PostgreSQL (start, query, import, backup)';

  PostgresCommand() {
    addSubcommand(PostgresStartCommand());
    addSubcommand(PostgresStatusCommand());
    addSubcommand(PostgresDbCommand());
    addSubcommand(PostgresTableCommand());
    addSubcommand(PostgresQueryCommand());
    addSubcommand(PostgresImportCommand());
    addSubcommand(PostgresImageCommand());
    addSubcommand(PostgresBackupCommand());
  }
}

/* =========================
   START / STATUS
   ========================= */

class PostgresStartCommand extends Command {
  @override
  final name = 'start';

  @override
  final description = 'Start local PostgreSQL';

  @override
  Future<void> run() async {
    logger.info('Starting PostgreSQL...');

    final dataDir = _pgDataDir();
    final args = dataDir != null
        ? ['start', '-D', dataDir]
        : ['start'];

    final result = await _run(
      _bin('pg_ctl'),
      args,
      inheritStdio: true,
    );

    if (result.exitCode != 0) {
      logger.err('Failed to start PostgreSQL');
    }
  }
}

class PostgresStatusCommand extends Command {
  @override
  final name = 'status';

  @override
  final description = 'Check PostgreSQL status';

  @override
  Future<void> run() async {
    final result = await _run(
      _bin('pg_ctl'),
      ['status'],
      inheritStdio: true,
    );

    if (result.exitCode != 0) {
      logger.err('PostgreSQL is not running');
    }
  }
}

/* =========================
   DATABASE
   ========================= */

class PostgresDbCommand extends Command {
  @override
  final name = 'db';

  @override
  final description = 'Database operations';

  PostgresDbCommand() {
    addSubcommand(PostgresDbList());
    addSubcommand(PostgresDbConnect());
  }
}

class PostgresDbList extends Command {
  @override
  final name = 'list';

  @override
  final description = 'List databases';

  @override
  Future<void> run() async {
    await _run(_bin('psql'), [
      '-c',
      "SELECT datname FROM pg_database WHERE datistemplate = false;"
    ]).then((r) => stdout.write(r.stdout));
  }
}

class PostgresDbConnect extends Command {
  @override
  final name = 'connect';

  @override
  final description = 'Connect to database';

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      logger.err('Database name required');
      return;
    }
    await _run(_bin('psql'), ['-d', argResults!.rest.first], inheritStdio: true);
  }
}

/* =========================
   TABLE
   ========================= */

class PostgresTableCommand extends Command {
  @override
  final name = 'table';

  @override
  final description = 'Table operations';

  PostgresTableCommand() {
    addSubcommand(PostgresTableList());
    addSubcommand(PostgresTableDescribe());
  }
}

class PostgresTableList extends Command {
  @override
  final name = 'list';

  @override
  final description = 'List tables';

  @override
  Future<void> run() async {
    final db = argResults!.rest.first;
    await _run(
      _bin('psql'),
      ['-d', db, '-c', "\\dt"],
    ).then((r) => stdout.write(r.stdout));
  }
}

class PostgresTableDescribe extends Command {
  @override
  final name = 'describe';

  @override
  final description = 'Describe table';

  @override
  Future<void> run() async {
    final args = argResults!.rest;
    await _run(
      _bin('psql'),
      ['-d', args[0], '-c', '\\d ${args[1]}'],
    ).then((r) => stdout.write(r.stdout));
  }
}

/* =========================
   QUERY
   ========================= */

class PostgresQueryCommand extends Command {
  @override
  final name = 'query';

  @override
  final description = 'Run SQL query';

  @override
  Future<void> run() async {
    final db = argResults!.rest.first;
    final sql = argResults!.rest.skip(1).join(' ');
    await _run(_bin('psql'), ['-d', db, '-c', sql])
        .then((r) => stdout.write(r.stdout));
  }
}

/* =========================
   IMPORT
   ========================= */

class PostgresImportCommand extends Command {
  @override
  final name = 'import';

  @override
  final description = 'Import CSV into table';

  @override
  Future<void> run() async {
    final args = argResults!.rest;
    final db = args[0];
    final table = args[1];
    final file = args[2];

    final sql =
        "\\copy $table FROM '$file' CSV HEADER";

    await _run(_bin('psql'), ['-d', db, '-c', sql])
        .then((r) => stdout.write(r.stdout));
  }
}

/* =========================
   IMAGE (BYTEA)
   ========================= */

class PostgresImageCommand extends Command {
  @override
  final name = 'image';

  @override
  final description = 'Store images in BYTEA';

  @override
  Future<void> run() async {
    final args = argResults!.rest;
    final db = args[0];
    final table = args[1];
    final column = args[2];
    final id = args[3];
    final file = args[4];

    final sql = """
UPDATE $table
SET $column = pg_read_binary_file('$file')
WHERE id = $id;
""";

    await _run(_bin('psql'), ['-d', db, '-c', sql])
        .then((r) => stdout.write(r.stdout));
  }
}

/* =========================
   BACKUP
   ========================= */

class PostgresBackupCommand extends Command {
  @override
  final name = 'backup';

  @override
  final description = 'Backup database';

  @override
  Future<void> run() async {
    final db = argResults!.rest[0];
    final out = argResults!.rest[1];
    await _run(_bin('pg_dump'), ['-Fc', db, '-f', out])
        .then((r) => stdout.write(r.stdout));
  }
}