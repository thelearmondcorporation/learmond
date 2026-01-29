import 'dart:io';
import 'package:args/command_runner.dart';

class CleanCommand extends Command {
  @override
  final name = 'clean';
  @override
  final description =
      'Clean macOS caches, simulators, and development workspace.';

  @override
  Future<void> run() async {
    print('Running Learmond clean...');

    final env = Platform.environment;

    // Determine DRY_RUN / ASSUME_YES from environment variables
    final dryRun = env['DRY_RUN'] == '1';
    final assumeYes = env['ASSUME_YES'] == '1';

    // Targets
    final home = Platform.environment['HOME']!;
    final targets = [
      '$home/Library/Developer/Xcode/DerivedData',
      '$home/Library/Developer/Caches',
      '$home/Library/Developer/Xcode/UserData',
      '$home/Library/Caches',
      '$home/Library/Metadata',
      '$home/Library/Biome',
      '$home/Library/.flutter', 
      '$home/Library/.fvm',
      '$home/Library/.docker',
      '$home/Library/.pub',
      '$home/Library/.gradle',
      '$home/Library/.pub-cache',
      '$home/Library/.dartServer',
      '$home/Library/.nvm',
      '$home/Library/.npm',
      '$home/Library/.cocoapods',
      '$home/Library/.rbenv',
      '$home/Library/.android/build-cache',
      '$home/Library/Containers/com.docker.docker',
      '$home/Library/Group Containers/group.com.docker',
      '$home/Library/Logs',
      '$home/Library/Preferences',
      '$home/Library/Saved Application State',
      '$home/Library/.hawtjni',
      '$home/Library/.dart-tool',
      '$home/Library/.zsh_sessions',
      '$home/Library/.pm2',
      '$home/Library/.render',
      '$home/Library/.gem',
      '$home/Library/.cagent',
      '$home/Library/.config',
      '$home/Library/.vscode',
      '$home/Library/.swiftpm',
      '$home/Library/.codex',
      '$home/Library/.expo',
      '$home/Library/.pyenv',
      '$home/Library/.cache',
      '$home/.Trash',
      '$home/Library/Application Support/Code/User/workspaceStorage',
    ];

    print('The following paths will be removed if they exist:');
    for (var p in targets) {
      final exists = Directory(p).existsSync() || File(p).existsSync();
      print('  ${exists ? 'EXISTS' : 'MISSING'}: $p');
    }

    if (!assumeYes) {
      stdout.write('\nType YES to delete: ');
      final confirm = stdin.readLineSync();
      if (confirm != 'YES') {
        print('Aborted — no changes made.');
        exit(0);
      }
    }

    for (var p in targets) {
      final file = File(p);
      final dir = Directory(p);
      if (file.existsSync()) {
        if (dryRun) {
          print('(dry-run) would remove file: $p');
        } else {
          file.deleteSync(recursive: true);
          print('Removed file: $p');
        }
      } else if (dir.existsSync()) {
        if (dryRun) {
          print('(dry-run) would remove dir: $p');
        } else {
          try {
            dir.deleteSync(recursive: true);
            print('Removed dir: $p');
          } catch (_) {
            print('Failed to remove dir: $p (maybe permissions)');
          }
        }
      }
    }

    // Optional: shutdown simulators
    if (Platform.isMacOS &&
        Process.runSync('xcrun', ['simctl', 'list']).exitCode == 0) {
      print('Shutting down all simulators...');
      if (!dryRun) {
        Process.runSync('xcrun', ['simctl', 'shutdown', 'all']);
      }
    }

    print('Cleanup complete.');
  }
}
