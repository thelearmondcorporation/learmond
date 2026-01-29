import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';
import 'license_command.dart' as license_lib;

class LicenseCliCommand extends Command {
  LicenseCliCommand() {
    argParser.addOption(
      'type',
      abbr: 't',
      defaultsTo: 'mit',
      help: 'License type to generate (mit, apache, gpl).',
    );
    argParser.addOption(
      'author',
      abbr: 'a',
      help:
          'Author name to include in copyright line. If omitted and running interactively, you will be prompted.',
    );
  }

  @override
  final name = 'license';

  @override
  final description = 'Check for or generate a LICENSE file.';

  @override
  Future<void> run() async {
    final licenseType = (argResults?['type'] ?? 'mit').toString().toLowerCase();
    final supported = ['mit', 'apache-2.0', 'gpl-3.0'];
    if (!supported.contains(licenseType)) {
      logger.err('Unsupported license type: $licenseType');
      exit(64);
    }
    logger.info('Running license command...');

    final licenseFiles = ['LICENSE', 'LICENSE.md', 'LICENSE.txt'];
    for (final p in licenseFiles) {
      if (await File(p).exists()) {
        logger.success('Found license file: $p');
        return;
      }
    }

    // No license file found; determine author and generate license
    try {
      String author;
      if (argResults?.wasParsed('author') ?? false) {
        author = (argResults?['author'] ?? '').toString().trim();
      } else if (stdin.hasTerminal) {
        stdout.write('Author name (press Enter to leave blank): ');
        author = (stdin.readLineSync() ?? '').trim();
      } else {
        // Non-interactive: default to empty author (no default)
        author = '';
      }

      final generator = license_lib.LicenseCommand(licenseType);
      generator.execute();

      // Prepend copyright line based on provided author (no default if empty)
      try {
        final file = File('LICENSE');
        final content = await file.readAsString();
        final year = DateTime.now().year;
        final owner = author;
        final copyrightLine = owner.isEmpty
            ? 'Copyright (c) $year'
            : 'Copyright (c) $year $owner';
        await file.writeAsString('$copyrightLine\n\n$content');
      } catch (e) {
        logger.err('Failed to update LICENSE with author: $e');
        exit(1);
      }

      logger.success('Created LICENSE (${licenseType.toUpperCase()}).');
    } catch (e) {
      logger.err('Failed to create LICENSE: $e');
      exit(1);
    }
  }
}
