import 'dart:io';

import 'package:args/command_runner.dart';

class PsqlCommand extends Command {
  @override
  final name = 'psql';

  @override
  final description =
      'PostgreSQL CLI. Use `learmond psql <db>` or `learmond psql <command>`.';

  static const Set<String> _commands = {
    'connect',
    'databases',
    'tables',
    'views',
    'describe',
    'indexes',
    'functions',
    'schema',
    'query',
  };

  @override
  String get usage => '''
Usage:
  learmond psql <database-or-connection-string>
  learmond psql connect [database-or-connection-string]
  learmond psql databases [database-or-connection-string]
  learmond psql tables [database-or-connection-string]
  learmond psql views [database-or-connection-string]
  learmond psql describe [database-or-connection-string]
  learmond psql indexes [database-or-connection-string]
  learmond psql functions [database-or-connection-string]
  learmond psql schema [database-or-connection-string]
  learmond psql query [database-or-connection-string]

If the database/connection is omitted, you will be prompted.
''';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];

    if (rest.isEmpty) {
      final target = await _resolveTarget();
      await _runPsql(_targetArgs(target));
      return;
    }

    final first = rest.first.trim();

    // Direct-connect mode: `learmond psql mydb`
    if (!_commands.contains(first.toLowerCase())) {
      final target = _targetFromRaw(first);
      await _runPsql(_targetArgs(target));
      return;
    }

    final command = first.toLowerCase();
    final rawTarget = rest.length > 1 ? rest[1].trim() : '';
    final target = rawTarget.isNotEmpty
        ? _targetFromRaw(rawTarget)
        : await _resolveTarget();

    switch (command) {
      case 'connect':
        await _runPsql(_targetArgs(target));
        return;
      case 'databases':
        await _runSql(
          target,
          "SELECT datname AS database_name FROM pg_database WHERE datistemplate = false ORDER BY datname;",
        );
        return;
      case 'tables':
        await _runSql(
          target,
          "SELECT table_schema, table_name FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND table_schema NOT IN ('pg_catalog', 'information_schema') ORDER BY table_schema, table_name;",
        );
        return;
      case 'views':
        await _runSql(
          target,
          "SELECT table_schema, table_name FROM information_schema.views WHERE table_schema NOT IN ('pg_catalog', 'information_schema') ORDER BY table_schema, table_name;",
        );
        return;
      case 'describe':
        stdout.write(
          'Enter table name to describe (leave empty to describe database): ',
        );
        final tableRaw = stdin.readLineSync()?.trim() ?? '';
        if (tableRaw.isEmpty) {
          await _runSql(
            target,
            "SELECT current_database() AS database_name, current_user AS current_user, version() AS server_version;",
          );
          return;
        }
        final table = tableRaw.replaceAll("'", "''");
        await _runSql(
          target,
          "SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = '$table' ORDER BY ordinal_position;",
        );
        return;
      case 'indexes':
        await _runSql(
          target,
          "SELECT schemaname, tablename, indexname, indexdef FROM pg_indexes WHERE schemaname NOT IN ('pg_catalog', 'information_schema') ORDER BY schemaname, tablename, indexname;",
        );
        return;
      case 'functions':
        await _runSql(
          target,
          "SELECT routine_schema, routine_name, data_type FROM information_schema.routines WHERE routine_schema NOT IN ('pg_catalog', 'information_schema') ORDER BY routine_schema, routine_name;",
        );
        return;
      case 'schema':
        await _runSql(
          target,
          "SELECT schema_name FROM information_schema.schemata ORDER BY schema_name;",
        );
        return;
      case 'query':
        stdout.write('Enter SQL query: ');
        final sql = stdin.readLineSync()?.trim() ?? '';
        if (sql.isEmpty) {
          stderr.writeln('SQL query is required.');
          exit(1);
        }
        await _runSql(target, sql);
        return;
      default:
        stderr.writeln(usage);
        exit(64);
    }
  }
}

class _PsqlTarget {
  final String value;
  final bool isConnectionString;

  _PsqlTarget(this.value, this.isConnectionString);
}

_PsqlTarget _targetFromRaw(String raw) {
  final value = raw.trim();
  return _PsqlTarget(value, value.contains('://'));
}

Future<_PsqlTarget> _resolveTarget({
  String prompt = 'Enter PostgreSQL database name or connection string',
}) async {
  stdout.write('$prompt: ');
  final raw = stdin.readLineSync()?.trim() ?? '';
  if (raw.isEmpty) {
    stderr.writeln('Database name or connection string is required.');
    exit(1);
  }
  return _targetFromRaw(raw);
}

List<String> _targetArgs(_PsqlTarget target) {
  if (target.isConnectionString) {
    return [target.value];
  }
  return ['-d', target.value];
}

Future<void> _runPsql(List<String> args) async {
  final p = await Process.start(
    Platform.isWindows ? 'psql.exe' : 'psql',
    args,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  final code = await p.exitCode;
  if (code != 0) {
    exit(code);
  }
}

Future<void> _runSql(_PsqlTarget target, String sql) async {
  final args = <String>[
    ..._targetArgs(target),
    '-c',
    sql,
  ];
  await _runPsql(args);
}
