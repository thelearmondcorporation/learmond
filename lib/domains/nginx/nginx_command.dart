import 'dart:io';

import 'package:args/command_runner.dart';

class NginxCommand extends Command {
  @override
  final name = 'nginx';

  @override
  final description = 'Manage nginx service: start, stop, reload, open config folder.';

  NginxCommand() {
    // Removed manual 'help' flag to prevent duplicate help error.
  }

  @override
  Future<void> run() async {
    if (argResults == null || argResults!.rest.isEmpty) {
      printUsage();
      return;
    }

    final subcommand = argResults!.rest.first;

    try {
      switch (subcommand) {
        case 'start':
          await _start();
          break;
        case 'stop':
          await _stop();
          break;
        case 'reload':
          await _reload();
          break;
        case 'open':
          await _openConfig();
          break;
        default:
          print('Unknown subcommand: $subcommand\n');
          printUsage();
          break;
      }
    } catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    }
  }

  void printUsage() {
    print('Usage: learmond <start|stop|reload|open> nginx');
    print('Subcommands:');
    print('  start   Start nginx service');
    print('  stop    Stop nginx service');
    print('  reload  Reload nginx configuration');
    print('  open    Open nginx configuration folder in nano editor');
  }

  Future<void> _start() async {
    print('Starting nginx service...');
    final result = await Process.run('brew', ['services', 'start', 'nginx']);
    if (result.exitCode == 0) {
      print('Nginx started successfully.');
    } else {
      stderr.writeln('Failed to start nginx: ${result.stderr}');
      exit(result.exitCode);
    }
  }

  Future<void> _stop() async {
    print('Stopping nginx service...');
    final result = await Process.run('brew', ['services', 'stop', 'nginx']);
    if (result.exitCode == 0) {
      print('Nginx stopped successfully.');
    } else {
      stderr.writeln('Failed to stop nginx: ${result.stderr}');
      exit(result.exitCode);
    }
  }

  Future<void> _reload() async {
    print('Testing nginx configuration...');
    final testResult = await Process.run('nginx', ['-t']);
    if (testResult.exitCode != 0) {
      stderr.writeln('Nginx configuration test failed:\n${testResult.stderr}');
      exit(testResult.exitCode);
    }
    print('Reloading nginx...');
    final reloadResult = await Process.run('sudo', ['nginx', '-s', 'reload']);
    if (reloadResult.exitCode == 0) {
      print('Nginx reloaded successfully.');
    } else {
      stderr.writeln('Failed to reload nginx: ${reloadResult.stderr}');
      exit(reloadResult.exitCode);
    }
  }

  Future<void> _openConfig() async {
    final configPath = _detectConfigPath();
    print('Opening nginx configuration folder: $configPath');
    final dir = Directory(configPath);
    if (!await dir.exists()) {
      stderr.writeln('Configuration directory does not exist: $configPath');
      exit(1);
    }

    final process = await Process.start('nano', [configPath], mode: ProcessStartMode.inheritStdio);
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      stderr.writeln('Failed to open nano editor with exit code $exitCode');
      exit(exitCode);
    }
  }

  String _detectConfigPath() {
    final arch = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '';
    if (arch.toLowerCase().contains('arm') || Platform.isMacOS && _isAppleSilicon()) {
      return '/opt/homebrew/etc/nginx';
    }
    return '/usr/local/etc/nginx';
  }

  bool _isAppleSilicon() {
    // On macOS, use sysctl to detect CPU type
    try {
      final result = Process.runSync('sysctl', ['-n', 'machdep.cpu.brand_string']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().toLowerCase();
        return output.contains('apple m1') || output.contains('apple m2') || output.contains('apple silicon');
      }
    } catch (_) {}
    return false;
  }
}
