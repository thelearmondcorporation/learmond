import 'dart:io';
import 'package:args/command_runner.dart';

class FlutterBuildAppBundleCommand extends Command {
  @override
  final name = 'appbundle';
  @override
  final description = 'Build release app bundle (AAB)';

  @override
  Future<void> run() async {
    print('Building release AppBundle (AAB)...');
    final result = await Process.run('flutter', [
      'build',
      'appbundle',
      '--release',
    ], runInShell: true);
    if (result.exitCode != 0) {
      print('Build failed:');
      print(result.stderr);
      return;
    }
    print('AppBundle built successfully.');
  }
}
