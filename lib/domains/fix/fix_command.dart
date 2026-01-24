import 'dart:io';
import 'package:args/command_runner.dart';

class FixCommand extends Command {
  @override
  final String name = 'fix';

  @override
  final String description =
      'Automatically fix common issues for the detected project type (Dart/Flutter, NPM, Ruby).';

  @override
  Future<void> run() async {
    final projectType = _detectProjectType();

    if (projectType == null) {
      stderr.writeln(
        'Unable to detect project type. Supported: Dart/Flutter, NPM, Ruby.',
      );
      exit(1);
    }

    switch (projectType) {
      case _ProjectType.flutter:
        await _runCommand('dart', [
          'fix',
          '--apply',
        ], description: 'Running dart fix --apply');
        break;

      case _ProjectType.dart:
        await _runCommand('dart', [
          'fix',
          '--apply',
        ], description: 'Running dart fix --apply');
        break;

      case _ProjectType.npm:
        await _runCommand('npm', [
          'audit',
          'fix',
        ], description: 'Running npm audit fix');
        break;

      case _ProjectType.ruby:
        await _runCommand('rubocop', [
          '-A',
        ], description: 'Running rubocop -A (auto-correct)');
        break;
    }
  }

  Future<void> _runCommand(
    String executable,
    List<String> args, {
    required String description,
  }) async {
    stdout.writeln(description);

    final result = await Process.run(executable, args, runInShell: true);

    if (result.stdout.toString().isNotEmpty) {
      stdout.write(result.stdout);
    }

    if (result.stderr.toString().isNotEmpty) {
      stderr.write(result.stderr);
    }

    if (result.exitCode != 0) {
      exit(result.exitCode);
    }
  }

  _ProjectType? _detectProjectType() {
    final cwd = Directory.current;

    if (File('${cwd.path}/pubspec.yaml').existsSync()) {
      if (Directory('${cwd.path}/android').existsSync() ||
          Directory('${cwd.path}/ios').existsSync()) {
        return _ProjectType.flutter;
      }
      return _ProjectType.dart;
    }

    if (File('${cwd.path}/package.json').existsSync()) {
      return _ProjectType.npm;
    }

    if (File('${cwd.path}/Gemfile').existsSync()) {
      return _ProjectType.ruby;
    }

    return null;
  }
}

enum _ProjectType { flutter, dart, npm, ruby }
