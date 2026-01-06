import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:learmond/core/context.dart';
import 'package:learmond/core/logger.dart';

class RepoInitCommand extends Command {
  final Context context;

  @override
  final name = 'init';

  @override
  final description =
      'Initialize a GitHub repository for the current directory';

  RepoInitCommand(this.context);

  @override
  Future<void> run() async {
    final dir = Directory.current.path;
    final name = p.basename(dir);

    logger.info('Initializing git repository');
    await _run('git', ['init']);
    await _run('git', ['add', '.']);
    await _run('git', ['commit', '-m', 'Initial commit']);

    logger.info('Creating GitHub repository ${context.org}/$name');
    await _run('gh', [
      'repo',
      'create',
      '${context.org}/$name',
      '--public',
      '--source=.',
      '--remote=origin',
    ]);

    logger.success('Repository ready: ${context.org}/$name');
  }

  Future<void> _run(String cmd, List<String> args) async {
    final result = await Process.run(cmd, args);
    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      exit(result.exitCode);
    }
  }
}
