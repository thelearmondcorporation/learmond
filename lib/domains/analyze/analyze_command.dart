import 'dart:io';
import 'package:args/command_runner.dart';

class AnalyzeCommand extends Command {
  @override
  final name = 'analyze';
  @override
  final description =
      'Run static analysis on the current project (Flutter, Dart, React Native, NPM, Ruby).';

  @override
  Future<void> run() async {
    print('Running Learmond analyzer...');

    final dir = Directory.current;
    final entries = dir.listSync();

    // Detect project type
    String? type;
    if (entries.any((e) => e is File && e.path.endsWith('pubspec.yaml'))) {
      if (entries.any((e) => e is Directory && e.path.endsWith('lib'))) {
        type = 'flutter';
      } else {
        type = 'dart';
      }
    } else if (entries.any(
      (e) => e is File && e.path.endsWith('package.json'),
    )) {
      // NPM / Node / React Native
      final packageJson = File('${dir.path}/package.json');
      final content = packageJson.readAsStringSync();
      if (content.contains('react-native')) {
        type = 'react-native';
      } else {
        type = 'npm';
      }
    } else if (entries.any((e) => e is File && e.path.endsWith('.gemspec'))) {
      type = 'ruby';
    }

    if (type == null) {
      print(
        'Could not detect project type. Supported: Flutter, Dart, React Native, NPM, Ruby.',
      );
      exit(1);
    }

    print('Detected project type: $type');

    int exitCode = 0;
    switch (type) {
      case 'flutter':
        exitCode = await _runProcess('flutter', ['analyze']);
        break;
      case 'dart':
        exitCode = await _runProcess('dart', ['analyze']);
        break;
      case 'react-native':
      case 'npm':
        // ESLint check
        exitCode = await _runProcess('npx', ['eslint', '.']);
        break;
      case 'ruby':
        exitCode = await _runProcess('rubocop', []);
        break;
    }

    if (exitCode != 0) {
      print('Analysis failed for project type $type.');
      exit(exitCode);
    }

    print('Analysis passed successfully.');
  }

  Future<int> _runProcess(String executable, List<String> arguments) async {
    print('Running: $executable ${arguments.join(' ')}');
    final result = await Process.run(executable, arguments, runInShell: true);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    return result.exitCode;
  }
}
