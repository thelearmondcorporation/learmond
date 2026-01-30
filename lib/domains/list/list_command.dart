import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

/// Cross-platform list command
/// Usage:
///   learmond list files [directory] [pattern]
///   learmond list apps [name]
///   learmond list ports [port]
class ListCommand extends Command {
  @override
  final name = 'list';

  @override
  final description = 'List files, running apps, or open ports (cross-platform).';

  @override
  Future<void> run() async {
    final args = argResults!.rest;

    if (args.isEmpty) {
      logger.err('Usage: learmond list {files|apps|ports}');
      return;
    }

    final subcommand = args[0];

    switch (subcommand) {
      case 'files':
        await _listFiles(
          args.length > 1 ? args[1] : '.',
          args.length > 2 ? args[2] : null,
        );
        break;

      case 'apps':
        await _listApps(args.length > 1 ? args[1] : null);
        break;

      case 'ports':
        await _listPorts(args.length > 1 ? args[1] : null);
        break;

      default:
        logger.err('Unknown list subcommand: $subcommand');
    }
  }

  Future<void> _listFiles(String directory, String? pattern) async {
    try {
      final isWindows = Platform.isWindows;

      final result = await Process.run(
        isWindows ? 'cmd' : 'ls',
        isWindows
            ? ['/c', 'dir', '/b', directory]
            : ['-1', directory],
      );

      if (result.exitCode != 0) {
        logger.err(result.stderr.toString());
        return;
      }

      final files = result.stdout
          .toString()
          .split('\n')
          .where((f) => f.trim().isNotEmpty);

      final filtered =
          pattern == null ? files : files.where((f) => f.contains(pattern));

      for (final file in filtered) {
        logger.info(file);
      }
    } catch (e) {
      logger.err('Failed to list files: $e');
    }
  }

  Future<void> _listApps(String? name) async {
    try {
      final isWindows = Platform.isWindows;

      final result = await Process.run(
        isWindows ? 'tasklist' : 'ps',
        isWindows ? [] : ['aux'],
      );

      if (result.exitCode != 0) {
        logger.err(result.stderr.toString());
        return;
      }

      final lines = result.stdout
          .toString()
          .split('\n')
          .where((l) => l.trim().isNotEmpty);

      final filtered = name == null
          ? lines
          : lines.where(
              (l) => l.toLowerCase().contains(name.toLowerCase()),
            );

      for (final line in filtered) {
        logger.info(line);
      }
    } catch (e) {
      logger.err('Failed to list apps: $e');
    }
  }

  Future<void> _listPorts(String? port) async {
    try {
      final isWindows = Platform.isWindows;

      final result = await Process.run(
        isWindows ? 'netstat' : 'lsof',
        isWindows ? ['-ano'] : ['-i'],
      );

      if (result.exitCode != 0) {
        logger.err(result.stderr.toString());
        return;
      }

      final lines = result.stdout
          .toString()
          .split('\n')
          .where((l) => l.trim().isNotEmpty);

      final filtered =
          port == null ? lines : lines.where((l) => l.contains(port));

      for (final line in filtered) {
        logger.info(line);
      }
    } catch (e) {
      logger.err('Failed to list ports: $e');
    }
  }
}