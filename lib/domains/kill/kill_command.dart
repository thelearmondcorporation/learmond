import 'dart:io';
import 'package:args/command_runner.dart';

class KillCommand extends Command<void> {
  @override
  final name = 'kill';

  @override
  final description = 'Kill a running process by port or app name';

  @override
  Future<void> run() async {
    stdout.write('Kill by (port/app): ');
    final choice = stdin.readLineSync()?.trim().toLowerCase();

    if (choice == 'port') {
      stdout.write('Enter port number: ');
      final portInput = stdin.readLineSync()?.trim();
      if (portInput == null || portInput.isEmpty) {
        stderr.writeln('No port number entered.');
        return;
      }

      try {
        final lsofResult = await Process.run('lsof', ['-ti', ':$portInput']);
        if (lsofResult.stdout.toString().trim().isEmpty) {
          stdout.writeln('No process found running on port $portInput.');
          return;
        }

        final pids = lsofResult.stdout.toString().trim().split('\n');
        for (final pid in pids) {
          await Process.run('kill', ['-9', pid]);
        }
        stdout.writeln('Killed process(es) running on port $portInput: ${pids.join(', ')}');
      } catch (e) {
        stderr.writeln('Failed to kill process on port $portInput: $e');
      }
    } else if (choice == 'app') {
      stdout.write('Enter app/process name: ');
      final appName = stdin.readLineSync()?.trim();
      if (appName == null || appName.isEmpty) {
        stderr.writeln('No app/process name entered.');
        return;
      }

      try {
        final pkillResult = await Process.run('pkill', ['-f', appName]);
        if (pkillResult.exitCode == 0) {
          stdout.writeln('Killed process(es) matching "$appName".');
        } else {
          stdout.writeln('No process found matching "$appName".');
        }
      } catch (e) {
        stderr.writeln('Failed to kill process matching "$appName": $e');
      }
    } else {
      stderr.writeln('Invalid choice. Please enter "port" or "app".');
    }
  }
}
