import 'dart:io';

import 'package:args/command_runner.dart';

class PublishCommand extends Command {
  @override
  final name = 'publish';

  @override
  final description = 'Run checks and publish the project.';

  PublishCommand() {
    argParser.addFlag(
      'dry-run',
      abbr: 'd',
      negatable: false,
      help: 'Run all checks, then prompt to publish if successful.',
    );
  }

  @override
  Future<void> run() async {
    final isDryRun = argResults?['dry-run'] == true;
    final steps = [
      ['learmond', 'fix'],
      ['learmond', 'analyze'],
      ['learmond', 'test'],
      ['learmond', 'format'],
      ['learmond', 'doctor'],
      ['learmond', 'license'],
      ['learmond', 'changelog'],
      ['learmond', 'push'],
    ];

    for (final step in steps) {
      final process = await Process.start(step[0], step.sublist(1));
      stdout.addStream(process.stdout);
      stderr.addStream(process.stderr);
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        stderr.writeln(
          'Error: command "${step.join(' ')}" failed with exit code $exitCode.',
        );
        exit(exitCode);
      }
    }

    if (isDryRun) {
      stdout.write('Dry run successful. Do you want to publish now? (yes/no) ');
      // Read user input interactively.
      String? answer = stdin.readLineSync();
      if (answer == null || answer.trim().toLowerCase() != 'yes') {
        stdout.writeln('Exiting without publishing.');
        return;
      }
    }

    // Detect project type
    final isFlutterOrDart = await _isFlutterOrDartProject();
    final isNpm = await _isNpmProject();
    final isRuby = await _isRubyProject();

    if (isFlutterOrDart) {
      final process = await Process.start('dart', [
        'pub',
        'publish',
        '--force',
      ]);
      stdout.addStream(process.stdout);
      stderr.addStream(process.stderr);
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        stderr.writeln(
          'Error: dart pub publish failed with exit code $exitCode.',
        );
        exit(exitCode);
      }
    } else if (isNpm) {
      final process = await Process.start('npm', ['publish']);
      stdout.addStream(process.stdout);
      stderr.addStream(process.stderr);
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        stderr.writeln('Error: npm publish failed with exit code $exitCode.');
        exit(exitCode);
      }
    } else if (isRuby) {
      final gemspec = await _findGemspec();
      if (gemspec == null) {
        stderr.writeln('Error: No gemspec file found for Ruby project.');
        exit(1);
      }
      final process = await Process.start('gem', ['push', gemspec]);
      stdout.addStream(process.stdout);
      stderr.addStream(process.stderr);
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        stderr.writeln('Error: gem push failed with exit code $exitCode.');
        exit(exitCode);
      }
    } else {
      stderr.writeln('Error: Could not detect project type for publishing.');
      exit(1);
    }
  }

  Future<bool> _isFlutterOrDartProject() async {
    final pubspec = File('pubspec.yaml');
    if (!await pubspec.exists()) return false;

    final content = await pubspec.readAsString();
    // Detect flutter or dart by checking for flutter sdk or environment sdk
    if (content.contains('flutter:') || content.contains('environment:')) {
      return true;
    }
    return false;
  }

  Future<bool> _isNpmProject() async {
    final packageJson = File('package.json');
    return await packageJson.exists();
  }

  Future<bool> _isRubyProject() async {
    final gemspec = await _findGemspec();
    return gemspec != null;
  }

  Future<String?> _findGemspec() async {
    final dir = Directory.current;
    final files = await dir.list().toList();
    for (final file in files) {
      if (file is File && file.path.endsWith('.gemspec')) {
        return file.path;
      }
    }
    return null;
  }
}
