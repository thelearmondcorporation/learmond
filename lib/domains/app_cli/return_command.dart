import 'dart:io';
import 'package:args/command_runner.dart';

class ReturnCommand extends Command {
  @override
  String get name => 'return';

  @override
  String get description => 'Run a local app-provided CLI (files ending in .cli or .click).';

  ReturnCommand();

  @override
  Future<void> run() async {
    final argsRest = argResults?.rest ?? [];
    if (argsRest.isEmpty) {
      stderr.writeln('Usage: learmond return <name> [args...]');
      exitCode = 64;
      return;
    }

    final cwd = Directory.current;
    final candidates = await _discoverCliFiles(cwd);

    final name = argsRest[0];
    final extraArgs = argsRest.sublist(1);

    final file = _selectCliByName(candidates, name);
    if (file == null) {
      stderr.writeln('No matching app CLI found for "$name". Use `--list` to see available CLIs.');
      exitCode = 2;
      return;
    }

    // Ensure executable on Unix-like systems
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', ['+x', file.path]);
      } catch (_) {
        // best-effort; continue
      }
    }

    final process = await Process.start(file.path, extraArgs, mode: ProcessStartMode.inheritStdio);
    final rc = await process.exitCode;
    if (rc != 0) {
      stderr.writeln('App CLI exited with code $rc');
      exit(rc);
    }
  }

  Future<List<File>> _discoverCliFiles(Directory dir) async {
    final List<File> found = [];
    try {
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (name.endsWith('.cli') || name.endsWith('.click')) {
            found.add(entity);
            continue;
          }
          // also consider files named <app>.cli or scripts with executable bit
        }
      }
      // also inspect possible 'bin' and 'tool' directories
      for (final sub in ['bin', 'tool']) {
        final d = Directory('${dir.path}/$sub');
        if (await d.exists()) {
          await for (final entity in d.list(recursive: false, followLinks: false)) {
            if (entity is File) {
              final name = entity.uri.pathSegments.last;
              if (name.endsWith('.cli') || name.endsWith('.click')) {
                found.add(entity);
              }
            }
          }
        }
      }
    } catch (_) {
      // ignore
    }
    return found;
  }

  File? _selectCliByName(List<File> candidates, String name) {
    // exact match
    for (final f in candidates) {
      final base = f.uri.pathSegments.last;
      if (base == name || base == '$name.cli' || base == '$name.click') return f;
    }
    // allow prefix match
    for (final f in candidates) {
      final base = f.uri.pathSegments.last;
      if (base.startsWith(name)) return f;
    }
    return null;
  }
}
