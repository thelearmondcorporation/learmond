import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';

class RunCommand extends Command {
  @override
  String get name => 'run';

  @override
  String get description =>
      'Detects the project type and runs the project accordingly.';

  @override
  Future<void> run() async {
    final projectType = await detectProjectType();
    if (projectType == null) {
      stderr.writeln('Could not detect project type.');
      exit(1);
    }

    final process = await runProject(projectType);
    if (process == null) {
      stderr.writeln('Failed to start the project.');
      exit(1);
    }

    // Stream stdout and stderr to console
    await Future.wait([
      stdout.addStream(process.stdout),
      stderr.addStream(process.stderr),
    ]);

    final exitCode = await process.exitCode;
    exit(exitCode);
  }
}

Future<String?> detectProjectType() async {
  final currentDir = Directory.current;

  if (await File('${currentDir.path}/pubspec.yaml').exists()) {
    final pubspec = await File(
      '${currentDir.path}/pubspec.yaml',
    ).readAsString();
    if (pubspec.contains('flutter:')) {
      return 'flutter';
    }
    return 'dart';
  }

  if (await File('${currentDir.path}/package.json').exists()) {
    final packageJson = await File(
      '${currentDir.path}/package.json',
    ).readAsString();
    if (packageJson.contains('react-native')) {
      return 'react-native';
    }
    return 'npm';
  }

  if (await File('${currentDir.path}/main.rb').exists()) {
    return 'ruby';
  }

  return null;
}

Future<Process?> runProject(String projectType) async {
  final currentDir = Directory.current;

  switch (projectType) {
    case 'flutter':
      return Process.start('flutter', ['run']);
    case 'dart':
      return Process.start('dart', ['run']);
    case 'react-native':
      return Process.start('npx', ['react-native', 'run-android']);
    case 'npm':
      // Try to determine main file from package.json
      final packageFile = File('${currentDir.path}/package.json');
      if (await packageFile.exists()) {
        final packageJson = await packageFile.readAsString();
        final mainFile =
            _extractMainFileFromPackageJson(packageJson) ?? 'index.js';
        return Process.start('node', [mainFile]);
      }
      return Process.start('node', ['index.js']);
    case 'ruby':
      return Process.start('ruby', ['main.rb']);
    default:
      return null;
  }
}

String? _extractMainFileFromPackageJson(String packageJson) {
  // Very simple JSON parsing to extract "main" field
  final mainRegex = RegExp(r'"main"\s*:\s*"([^"]+)"');
  final match = mainRegex.firstMatch(packageJson);
  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }
  return null;
}
