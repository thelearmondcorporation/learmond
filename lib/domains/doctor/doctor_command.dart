import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

class DoctorCommand extends Command {
  @override
  final name = 'doctor';

  @override
  final description = 'Check your environment for required tools and setup.';

  @override
  Future<void> run() async {
    logger.info('Running preflight checks...');

    final checks = <String, bool>{
      'Git': await _isInstalled('git', ['--version']),
      'GitHub CLI (gh)': await _isInstalled('gh', ['--version']),
      'GitHub Auth': await _checkGhAuth(),
      'Dart SDK': await _isInstalled('dart', ['--version']),
      'Flutter SDK': await _isInstalled('flutter', ['--version']),
      'Node.js': await _isInstalled('node', ['--version']),
      'NPM': await _isInstalled('npm', ['--version']),
      'Ruby': await _isInstalled('ruby', ['--version']),
      'Android SDK (ANDROID_HOME)': _checkAndroidHome(),
      'Android SDK (adb)': await _isInstalled('adb', ['version']),
      'Xcode': await _checkXcode(),
    };

    for (final entry in checks.entries) {
      if (entry.value) {
        logger.success('${entry.key} is installed ✅');
      } else {
        logger.err('${entry.key} is missing ❌');
      }
    }

    final allOk = checks.values.every((v) => v);
    if (allOk) {
      logger.info('All checks passed. Environment is ready.');
    } else {
      logger.err(
        'Some checks failed. Fix the issues above before running commands.',
      );
      exit(1);
    }
  }

  /// Checks if a command exists and runs without error
  Future<bool> _isInstalled(String command, List<String> args) async {
    try {
      final result = await Process.run(command, args);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Checks if GitHub CLI is authenticated
  Future<bool> _checkGhAuth() async {
    try {
      final result = await Process.run('gh', ['auth', 'status']);
      return result.exitCode == 0 &&
          result.stdout.toString().contains('Logged in as');
    } catch (_) {
      return false;
    }
  }

  /// Checks if ANDROID_HOME environment variable is set
  bool _checkAndroidHome() {
    final androidHome = Platform.environment['ANDROID_HOME'];
    return androidHome != null && androidHome.isNotEmpty;
  }

  /// Checks if Xcode is installed by running xcode-select -p
  Future<bool> _checkXcode() async {
    try {
      final result = await Process.run('xcode-select', ['-p']);
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
