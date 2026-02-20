import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

class SshCommand extends Command {
  @override
  final name = 'ssh';

  @override
  final description = 'SSH helper commands';

  SshCommand() {
    addSubcommand(SshHetznerCommand());
  }
}

class SshHetznerCommand extends Command {
  @override
  final name = 'hetzner';

  @override
  final description = 'SSH into a Hetzner server as root (prompts for IP if not provided)';

  SshHetznerCommand();

  @override
  Future<void> run() async {
    String ip;
    if (argResults == null || argResults!.rest.isEmpty) {
      stdout.write('Hetzner server IP address: ');
      ip = stdin.readLineSync() ?? '';
    } else {
      ip = argResults!.rest.first;
    }

    ip = ip.trim();
    if (ip.isEmpty) {
      logger.err('IP address required');
      printUsage();
      return;
    }

    logger.info('Connecting to root@$ip via learmond ssh...');
    try {
      final process = await Process.start(
        'learmond',
        ['ssh', 'root@$ip'],
        runInShell: true,
      );
      await stdout.addStream(process.stdout);
      await stderr.addStream(process.stderr);
      final code = await process.exitCode;
      if (code != 0) {
        logger.err('ssh exited with code $code');
      }
    } catch (e) {
      logger.err('Failed to run ssh: $e');
    }
  }
}

