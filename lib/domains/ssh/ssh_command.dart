import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

class SshCommand extends Command {
  @override
  final name = 'ssh';

  @override
  final description =
      'SSH into a host/IP, environment alias, or file-path alias. Usage: learmond ssh <host|VAR|\$VAR|path>';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];

    bool hetznerMode = false;
    String input;

    if (rest.isEmpty) {
      stdout.write('Server host/IP, env alias, or alias file path: ');
      input = stdin.readLineSync() ?? '';
    } else if (rest.first == 'hetzner') {
      hetznerMode = true;
      if (rest.length > 1) {
        input = rest[1];
      } else {
        stdout.write('Hetzner server IP, env alias, or alias file path: ');
        input = stdin.readLineSync() ?? '';
      }
    } else {
      input = rest.first;
    }

    final resolved = _resolveHostFromAlias(input).trim();
    if (resolved.isEmpty) {
      logger.err('Host/IP required');
      printUsage();
      return;
    }

    final target = _buildSshTarget(resolved, hetznerMode: hetznerMode);

    logger.info('Connecting to $target via ssh...');
    try {
      final process = await Process.start(
        'ssh',
        [target],
        mode: ProcessStartMode.inheritStdio,
        runInShell: true,
      );
      final code = await process.exitCode;
      if (code != 0) {
        logger.err('ssh exited with code $code');
      }
    } catch (e) {
      logger.err('Failed to run ssh: $e');
    }
  }

  String _resolveHostFromAlias(String rawInput) {
    final raw = rawInput.trim();
    if (raw.isEmpty) {
      return '';
    }

    final envKey = raw.startsWith(r'$') ? raw.substring(1) : raw;
    final envValue = Platform.environment[envKey];
    if (envValue != null && envValue.trim().isNotEmpty) {
      return envValue.trim();
    }

    final maybePath = _expandHome(raw);
    final aliasFile = File(maybePath);
    if (aliasFile.existsSync()) {
      final fromFile = _readAliasFile(aliasFile);
      if (fromFile.isNotEmpty) {
        return fromFile;
      }
    }

    return raw;
  }

  String _buildSshTarget(String hostOrTarget, {required bool hetznerMode}) {
    final value = hostOrTarget.trim();
    if (value.isEmpty) {
      return value;
    }
    if (value.contains('@')) {
      return value;
    }
    // Default to root login for server-style usage unless user is provided.
    return 'root@$value';
  }

  String _expandHome(String path) {
    if (!path.startsWith('~/')) {
      return path;
    }
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return path;
    }
    return '$home/${path.substring(2)}';
  }

  String _readAliasFile(File file) {
    try {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          continue;
        }

        if (trimmed.contains('=')) {
          final parts = trimmed.split('=');
          if (parts.length >= 2) {
            final value = parts.sublist(1).join('=').trim();
            if (value.isNotEmpty) {
              return value;
            }
          }
        }

        return trimmed;
      }
    } catch (_) {
      // best effort; fall back to raw input
    }
    return '';
  }
}
