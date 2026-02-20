import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

class LsofCommand extends Command {
  @override
  final name = 'lsof';

  @override
  final description = 'Run lsof against a port and optionally filter by app. Usage: learmond lsof <port> / <app>';

  LsofCommand();

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];

    if (args.isEmpty) {
      logger.err('Port number required');
      printUsage();
      return;
    }

    // Parse possible formats: ["8080", "/", "app"], ["8080/app"], ["8080", "/app"], ["8080", "app"]
    String portStr = args[0];
    String? app;

    if (args.length >= 3 && args[1] == '/') {
      app = args[2];
    } else if (args.length >= 2 && args[1].startsWith('/')) {
      app = args[1].substring(1);
    } else if (portStr.contains('/')) {
      final parts = portStr.split('/');
      portStr = parts[0];
      if (parts.length > 1) app = parts.sublist(1).join('/');
    } else if (args.length >= 2) {
      // support: lsof 8080 app
      app = args[1];
    }

    portStr = portStr.trim();
    if (portStr.isEmpty) {
      logger.err('Port number required');
      printUsage();
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null) {
      logger.err('Invalid port: $portStr');
      return;
    }

    logger.info('Running lsof on port $port${app != null ? ' and filtering by $app' : ''}');

    try {
      final result = await Process.run('lsof', ['-i', ':$port'], runInShell: true);
      final out = result.stdout.toString();
      final err = result.stderr.toString();

      if (result.exitCode != 0 && out.trim().isEmpty) {
        // lsof exit code 1 often indicates no matches; report more user-friendly message
        logger.info('No processes found using port $port.');
        return;
      }

      if (app == null) {
        stdout.write(out);
        if (err.isNotEmpty) stderr.write(err);
      } else {
        final String appName = app;
        final lines = out.split('\n');
        final filtered = lines.where((l) => l.contains(appName)).toList();
        if (filtered.isEmpty) {
          logger.info('No processes found for app "$appName" using port $port.');
        } else {
          logger.info(filtered.join('\n'));
        }
        if (err.isNotEmpty) stderr.write(err);
      }

      if (result.exitCode != 0) logger.err('lsof exited with code ${result.exitCode}');
    } catch (e) {
      logger.err('Failed to run lsof: $e');
    }
  }
}
