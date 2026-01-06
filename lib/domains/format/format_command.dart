import 'dart:io';

import 'package:args/command_runner.dart';

class FormatCommand extends Command {
  @override
  final name = 'format';
  @override
  final description = 'Run formatting/linting based on project type.';

  @override
  Future<void> run() async {
    if (await _isFlutterProject()) {
      await _runCommand('dart', ['format', '.']);
    } else if (await _isReactNativeProject()) {
      await _runCommand('npx', ['prettier', '--write', '.']);
    } else if (await _isRubyProject()) {
      await _runCommand('rubocop', ['-A']);
    } else {
      print('No supported project type detected for formatting.');
    }
  }

  Future<bool> _isFlutterProject() async {
    return File('pubspec.yaml').existsSync();
  }

  Future<bool> _isReactNativeProject() async {
    return File('package.json').existsSync();
  }

  Future<bool> _isRubyProject() async {
    return File('Gemfile').existsSync();
  }

  Future<void> _runCommand(String executable, List<String> arguments) async {
    final process = await Process.start(executable, arguments);
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print(
        'Command $executable ${arguments.join(' ')} failed with exit code $exitCode',
      );
      exit(exitCode);
    }
  }
}
