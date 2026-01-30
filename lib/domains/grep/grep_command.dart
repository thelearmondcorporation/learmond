import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

class GrepCommand extends Command {
  @override
  final name = 'grep';

  @override
  final description =
      'Search files, running apps, or ports across macOS, Linux, and Windows.';

  @override
  Future<void> run() async {
    if (argResults == null || argResults!.rest.isEmpty) {
      logger.err('No arguments provided.');
      return;
    }

    final args = argResults!.rest;
    final firstArg = args[0].toLowerCase();

    if (firstArg == 'port') {
      if (args.length < 2) {
        logger.err('Usage: learmond grep port {port}');
        return;
      }
      await _listProcessesUsingPort(args[1]);
      return;
    }

    if (firstArg == 'apps') {
      final appName = args.length > 1 ? args[1] : null;
      await _listRunningProcesses(appName);
      return;
    }

    await _searchFiles(firstArg);
  }

  Future<void> _listProcessesUsingPort(String port) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('lsof', ['-i', ':$port']);
        if (result.exitCode != 0 ||
            result.stdout.toString().trim().isEmpty) {
          logger.info('No processes found using port $port.');
          return;
        }
        logger.info(result.stdout.toString());
      } else if (Platform.isWindows) {
        final netstat = await Process.run('netstat', ['-ano']);
        final lines = netstat.stdout.toString().split('\n');
        final matches = lines.where((l) => l.contains(':$port')).toList();

        if (matches.isEmpty) {
          logger.info('No processes found using port $port.');
          return;
        }

        for (final line in matches) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 5) {
            final pid = parts.last;
            final task = await Process.run(
              'tasklist',
              ['/FI', 'PID eq $pid'],
            );
            logger.info(task.stdout.toString());
          }
        }
      }
    } catch (e) {
      logger.err('Failed to inspect port $port: $e');
    }
  }

  Future<void> _listRunningProcesses(String? appName) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('ps', ['-ax']);
        final lines = result.stdout.toString().split('\n');
        final filtered = appName == null
            ? lines
            : lines.where(
                (l) => l.toLowerCase().contains(appName.toLowerCase()),
              );

        logger.info(filtered.join('\n'));
      } else if (Platform.isWindows) {
        final result = await Process.run('tasklist', []);
        final lines = result.stdout.toString().split('\n');
        final filtered = appName == null
            ? lines
            : lines.where(
                (l) => l.toLowerCase().contains(appName.toLowerCase()),
              );

        logger.info(filtered.join('\n'));
      }
    } catch (e) {
      logger.err('Failed to list running applications: $e');
    }
  }

  Future<void> _searchFiles(String pattern) async {
    final root = Directory.current;
    final regex = RegExp(pattern);

    await for (final entity in root.list(recursive: true)) {
      if (entity is File) {
        final lines = await entity.readAsLines();
        for (var i = 0; i < lines.length; i++) {
          if (regex.hasMatch(lines[i])) {
            logger.info('${entity.path}:${i + 1} ${lines[i]}');
          }
        }
      }
    }
  }
}