import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

class FindCommand extends Command {
  @override
  final name = 'find';

  @override
  final description = 'Find files anywhere on the system by name (like: find / -name "*.conf").';

  FindCommand() {
    // No flags needed; always searches from root.
  }

  @override
  Future<void> run() async {
    if (argResults == null || argResults!.rest.isEmpty) {
      logger.err('Usage: learmond find <pattern>');
      exit(1);
    }

    final pattern = argResults!.rest.first;
    String trimmedPattern = pattern;
    if (trimmedPattern.startsWith('"') || trimmedPattern.startsWith("'")) {
      trimmedPattern = trimmedPattern.substring(1);
    }
    if (trimmedPattern.endsWith('"') || trimmedPattern.endsWith("'")) {
      trimmedPattern = trimmedPattern.substring(0, trimmedPattern.length - 1);
    }
    final startPaths = [
      '/opt/homebrew/etc',
      '/usr/local/etc',
      '/etc',
      '/Users'
    ];

    logger.info('Searching for "$trimmedPattern"...');

    final regex = _globToRegex(trimmedPattern);
    var found = false;

    for (final startPath in startPaths) {
      logger.info('Search root: $startPath');
      try {
        await for (final entity in Directory(startPath).list(
          recursive: true,
          followLinks: false,
        )) {
          try {
            final name = entity.uri.pathSegments.last;
            if (regex.hasMatch(name)) {
              logger.success(entity.path);
              found = true;
            }
          } on FileSystemException catch (e) {
            logger.info('Skipped unreadable file or directory: ${e.path}');
            continue;
          }
        }
      } on FileSystemException {
        // Skip unreadable directory silently
        continue;
      }
    }

    if (!found) {
      logger.info('No matching files found.');
    }
  }

  RegExp _globToRegex(String glob) {
    final escaped = RegExp.escape(glob)
        .replaceAll(r'\*', '.*')
        .replaceAll(r'\?', '.');
    return RegExp('^$escaped\$');
  }
}