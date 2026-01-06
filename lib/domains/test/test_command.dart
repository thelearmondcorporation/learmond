import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

class TestCommand extends Command {
  @override
  final name = 'test';

  @override
  final description = 'Run tests for the detected project type.';

  TestCommand();

  @override
  Future<void> run() async {
    final directory = Directory.current;

    final isFlutter = await _isFlutterProject(directory);
    final isDart = await _isDartProject(directory);
    final isReactNative = await _isReactNativeProject(directory);
    final isRuby = await _isRubyProject(directory);

    if (isFlutter) {
      await _runCommand('flutter', ['test']);
    } else if (isDart) {
      await _runCommand('dart', ['test']);
    } else if (isReactNative) {
      await _runCommand('npm', ['test']);
    } else if (isRuby) {
      await _runCommand('rspec', []);
    } else {
      stderr.writeln(
        'Could not detect project type or no test command available.',
      );
      exit(1);
    }
  }
}

Future<bool> _isFlutterProject(Directory dir) async {
  final pubspecFile = File('${dir.path}/pubspec.yaml');
  if (!await pubspecFile.exists()) return false;
  final content = await pubspecFile.readAsString();
  return content.contains('flutter:');
}

Future<bool> _isDartProject(Directory dir) async {
  final pubspecFile = File('${dir.path}/pubspec.yaml');
  if (!await pubspecFile.exists()) return false;
  final content = await pubspecFile.readAsString();
  // Consider Dart project if pubspec.yaml exists and no flutter key
  return !content.contains('flutter:');
}

Future<bool> _isReactNativeProject(Directory dir) async {
  final packageJsonFile = File('${dir.path}/package.json');
  if (!await packageJsonFile.exists()) return false;
  final content = await packageJsonFile.readAsString();
  return content.contains('react-native');
}

Future<bool> _isRubyProject(Directory dir) async {
  final gemfile = File('${dir.path}/Gemfile');
  final rspecDir = Directory('${dir.path}/spec');
  return await gemfile.exists() && await rspecDir.exists();
}

Future<void> _runCommand(String executable, List<String> arguments) async {
  final process = await Process.start(executable, arguments);

  // Stream stdout
  process.stdout.transform(SystemEncoding().decoder).listen(stdout.write);
  // Stream stderr
  process.stderr.transform(SystemEncoding().decoder).listen(stderr.write);

  final exitCode = await process.exitCode;
  exit(exitCode);
}
