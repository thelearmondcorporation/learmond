import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

class FindCommand extends Command {
  @override
  final name = 'find';

  @override
  final description =
      'Find files by name: quick results in current folder, then background full-system search.';

  FindCommand();

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
    logger.info('Quick search in current folder for "$trimmedPattern"...');
    final regex = _globToRegex(trimmedPattern);
    final found = <String>{};
    await _quickSearchInCurrentFolder(regex, found);

    if (found.isEmpty) {
      logger.info('No quick matches in ${Directory.current.path}.');
    }

    final logPath = await _startBackgroundSystemSearch(trimmedPattern);
    logger.info('Background full-system search started.');
    logger.info('Results file: $logPath');
    logger.info('Follow results with: tail -f $logPath');
  }

  Future<void> _quickSearchInCurrentFolder(RegExp regex, Set<String> found) async {
    final cwd = Directory.current.path;
    final rg = Platform.isWindows ? 'rg.exe' : 'rg';
    final rgAvailable = await _commandExists(rg);

    if (rgAvailable) {
      final p = await Process.start(
        rg,
        ['--files', cwd],
        runInShell: true,
      );

      await for (final line in p.stdout.transform(SystemEncoding().decoder).transform(const LineSplitter())) {
        final path = line.trim();
        if (path.isEmpty) continue;
        final name = path.split(Platform.pathSeparator).last;
        if (regex.hasMatch(name) && found.add(path)) {
          logger.success(path);
        }
      }
      await p.exitCode;
      return;
    }

    try {
      await for (final entity in Directory(cwd).list(
        recursive: true,
        followLinks: false,
      )) {
        final name = entity.uri.pathSegments.isEmpty
            ? entity.path
            : entity.uri.pathSegments.last;
        if (regex.hasMatch(name) && found.add(entity.path)) {
          logger.success(entity.path);
        }
      }
    } on FileSystemException {
      // best effort only
    }
  }

  Future<String> _startBackgroundSystemSearch(String pattern) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final logPath = '/tmp/learmond_find_$stamp.log';
    final escapedPattern = pattern.replaceAll("'", r"'\''");
    final hasWildcard = pattern.contains('*') || pattern.contains('?');
    final namePattern = hasWildcard ? escapedPattern : '*$escapedPattern*';

    // Robust whole-machine search in the background.
    final script = "nohup find / -iname '$namePattern' 2>/dev/null > '$logPath' &";

    await Process.run(
      'sh',
      ['-lc', script],
    );

    return logPath;
  }

  Future<bool> _commandExists(String command) async {
    final checkCmd = Platform.isWindows ? 'where' : 'command';
    final checkArgs = Platform.isWindows
        ? [command]
        : ['-v', command];
    final result = await Process.run(
      checkCmd,
      checkArgs,
      runInShell: true,
    );
    return result.exitCode == 0;
  }

  RegExp _globToRegex(String glob) {
    final escaped = RegExp.escape(glob)
        .replaceAll(r'\*', '.*')
        .replaceAll(r'\?', '.');
    return RegExp('^$escaped\$');
  }
}
