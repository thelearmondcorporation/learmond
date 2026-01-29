import 'dart:io';
import 'package:args/command_runner.dart';
import '../../core/logger.dart';

class StorageCommand extends Command {
  @override
  final name = 'storage';

  @override
  final description = 'Check disk space and show usage summary for common paths.';

  StorageCommand() {
    argParser
      ..addOption('path', abbr: 'p', help: 'Comma-separated list of paths to check (e.g. /, /Users).')
      ..addOption('warn', abbr: 'w', help: 'Warn when available percent is less than this value.', defaultsTo: '10');
  }

  @override
  Future<void> run() async {
    final warnThreshold = int.tryParse(argResults?['warn'] ?? '10') ?? 10;

    // Build paths to check
    final optionPath = argResults?['path'] as String?;
    final rest = argResults?.rest ?? [];

    final List<String> targets = [];
    if (rest.isNotEmpty) {
      targets.addAll(rest);
    } else if (optionPath != null && optionPath.isNotEmpty) {
      targets.addAll(optionPath.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    } else {
      // sensible defaults
      targets.addAll([Directory.current.path, '/', '/Users']);
    }

    final List<String> lowPaths = [];

    for (final path in targets) {
      final isLow = await _checkPath(path, warnThreshold);
      if (isLow == true) lowPaths.add(path);
    }

    // Summary
    if (lowPaths.isNotEmpty) {
      logger.err('\n⚠️ Low disk space detected for ${lowPaths.length} path(s):');
      for (final p in lowPaths) {
        logger.err('  - $p');
      }
      logger.err('Consider removing large files or increasing disk size.');
    } else {
      logger.success('\nAll checked paths have sufficient available disk space.');
    }
  }

  Future<bool> _checkPath(String path, int warnThreshold) async {
    final p = path.trim();
    if (p.isEmpty) return false;

    if (!await Directory(p).exists()) {
      logger.err('Path does not exist: $p');
      return false;
    }

    try {
      // POSIX-friendly df in KB so we can parse numerically
      final proc = await Process.run('df', ['-k', p]);
      if (proc.exitCode != 0) {
        logger.err('Failed to run df on $p: ${proc.stderr}');
        return false;
      }

      final out = (proc.stdout as String).trim();
      final lines = out.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        // Nothing to parse
        logger.info('df output for $p:\n$out');
        return false;
      }

      // Prefer the last data line (handles wrapped filesystem names)
      final dataLine = lines.last;
      final cols = dataLine.split(RegExp(r'\s+'));
      if (cols.length < 2) {
        logger.info('df output for $p:\n$out');
        return false;
      }

      // Find the capacity column (a token ending with '%') and derive positions relative to it
      final capIndex = cols.indexWhere((c) => c.trim().endsWith('%'));

      int totalKb = 0;
      int usedKb = 0;
      int availKb = 0;
      String capacity = '';
      String mount = '?';

      final filesystem = cols.first;

      if (capIndex != -1) {
        capacity = cols[capIndex];
        if (capIndex >= 3) {
          totalKb = int.tryParse(cols[capIndex - 3]) ?? 0;
          usedKb = int.tryParse(cols[capIndex - 2]) ?? 0;
          availKb = int.tryParse(cols[capIndex - 1]) ?? 0;
        } else if (cols.length >= 4) {
          // Fallback to common positions
          totalKb = int.tryParse(cols[1]) ?? 0;
          usedKb = int.tryParse(cols[2]) ?? 0;
          availKb = int.tryParse(cols[3]) ?? 0;
        }
        if (cols.length > capIndex + 1) {
          mount = cols.sublist(capIndex + 1).join(' ');
        }
      } else {
        // Last resort fallback
        if (cols.length >= 4) {
          totalKb = int.tryParse(cols[1]) ?? 0;
          usedKb = int.tryParse(cols[2]) ?? 0;
          availKb = int.tryParse(cols[3]) ?? 0;
        }
        mount = cols.length >= 6 ? cols.sublist(5).join(' ') : (cols.length > 1 ? cols.last : '?');
      }

      // Heuristic: ensure mount looks like a path (starts with '/'); otherwise try to find a token from right that is a path
      if (!mount.startsWith('/') && mount != '?') {
        for (var i = cols.length - 1; i >= 0; i--) {
          final token = cols[i];
          if (token.startsWith('/')) {
            mount = cols.sublist(i).join(' ');
            break;
          }
        }
      }

      final total = _humanReadableFromKb(totalKb);
      final used = _humanReadableFromKb(usedKb);
      final avail = _humanReadableFromKb(availKb);

      final percentStr = capacity.replaceAll('%', '') ;
      final usedPercent = int.tryParse(percentStr) ?? ((totalKb == 0) ? 0 : ((usedKb * 100) ~/ (totalKb)));

      final msg = '\nFilesystem: $filesystem\nMounted on: $mount\n  Total: $total  Used: $used ($usedPercent%)  Avail: $avail';

      if (100 - usedPercent <= warnThreshold) {
        logger.err('Low disk space:$msg');
        return true;
      } else {
        logger.success('OK:$msg');
        return false;
      }
    } catch (e) {
      logger.err('Error checking path $p: $e');
      return false;
    }
  }

  String _humanReadableFromKb(int kb) {
    if (kb <= 0) return '0B';
    final bytes = kb * 1024; // convert KB to bytes
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex += 1;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)}${units[unitIndex]}';
  }

  String _humanReadableFromBytes(int bytes) {
    if (bytes <= 0) return '0B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex += 1;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)}${units[unitIndex]}';
  }
}

// Helper function that implements the largest-files logic so multiple commands can call it.
Future<void> showLargestFiles({required String path, required int n, required bool recursive, required bool includeHidden}) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    logger.err('Path does not exist: $path');
    return;
  }

  final List<Map<String, dynamic>> top = [];
  try {
      int skipped = 0;
      final stream = dir.list(recursive: recursive, followLinks: false).handleError((e) {
        skipped += 1;
        logger.info('Skipping unreadable path during traversal: $e');
      }, test: (e) => true);

      await for (final entity in stream) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (!includeHidden && name.startsWith('.')) continue;
          try {
            final len = await entity.length();
            if (top.length < n) {
              top.add({'path': entity.path, 'size': len});
              top.sort((a, b) => a['size'].compareTo(b['size']));
            } else if (len > top.first['size']) {
              top[0] = {'path': entity.path, 'size': len};
              top.sort((a, b) => a['size'].compareTo(b['size']));
            }
          } catch (e) {
            logger.info('Skipping file ${entity.path}: $e');
            continue;
          }
        }
      }

      if (skipped > 0) {
        logger.info('Note: skipped $skipped unreadable path(s) while scanning.');
      }
    } catch (e) {
      logger.err('Error scanning directory $path: $e');
      return;
    }
  if (top.isEmpty) {
    logger.info('No files found at $path');
    return;
  }

  top.sort((a, b) => b['size'].compareTo(a['size']));
  logger.info('\nTop ${top.length} files under $path:');
  var idx = 1;
  for (final entry in top) {
    final size = entry['size'] as int;
    logger.info('${idx.toString().padLeft(2)}. ${_humanReadableFromBytes(size).padLeft(8)}  ${entry['path']}');
    idx += 1;
  }
}

// Command kept for direct usage (legacy): still available as `learmond largest` if desired.
class LargestFilesCommand extends Command {
  @override
  final name = 'largest';

  @override
  final description = 'Print the N largest files under a given path.';

  LargestFilesCommand() {
    argParser
      ..addOption('path', abbr: 'p', help: 'Path to search (default: root `/` — scans entire machine; may skip permission-limited folders).', defaultsTo: '/')
      ..addOption('num', abbr: 'n', help: 'Number of files to show.', defaultsTo: '10')
      ..addFlag('recursive', abbr: 'r', help: 'Search directories recursively.', defaultsTo: true)
      ..addFlag('hidden', help: 'Include hidden files (starting with .)', defaultsTo: false);
  }

  @override
  Future<void> run() async {
    final n = int.tryParse(argResults?['num'] ?? '10') ?? 10;
    final path = (argResults?['path'] as String?) ?? '/';
    final recursive = argResults?['recursive'] as bool? ?? true;
    final includeHidden = argResults?['hidden'] as bool? ?? false;

    await showLargestFiles(path: path, n: n, recursive: recursive, includeHidden: includeHidden);
  }
}

// New `print` command that dispatches sub-commands like `largest files`.
class PrintLargestFilesCommand extends Command {
  @override
  final name = 'print';

  @override
  final description = 'Print various diagnostics and information (e.g., largest files).';

  PrintLargestFilesCommand() {
    // Accept options that are relevant to some subcommands (largest files)
    argParser
      ..addOption('path', abbr: 'p', help: 'Path to search (default: root `/` — scans entire machine; may skip permission-limited folders).', defaultsTo: '/')
      ..addOption('num', abbr: 'n', help: 'Number of files to show.', defaultsTo: '10')
      ..addFlag('recursive', abbr: 'r', help: 'Search directories recursively.', defaultsTo: true)
      ..addFlag('hidden', help: 'Include hidden files (starting with .)', defaultsTo: false);
  }

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.length >= 2 && rest[0] == 'largest' && rest[1] == 'files') {
      final n = int.tryParse(argResults?['num'] ?? '10') ?? 10;
      final path = (argResults?['path'] as String?) ?? '.';
      final recursive = argResults?['recursive'] as bool? ?? true;
      final includeHidden = argResults?['hidden'] as bool? ?? false;
      await showLargestFiles(path: path, n: n, recursive: recursive, includeHidden: includeHidden);
      return;
    }

    // Unknown/missing subcommand
    logger.info('Usage: learmond print <subcommand> [options]\nAvailable subcommands:\n  largest files    Print the N largest files under a path');
  }
}

String _humanReadableFromBytes(int bytes) {
  if (bytes <= 0) return '0B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex += 1;
  }
  return '${size.toStringAsFixed(size >= 10 ? 0 : 1)}${units[unitIndex]}';
}