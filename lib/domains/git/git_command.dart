import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:learmond/core/context.dart';
import 'package:learmond/core/logger.dart';
import 'package:path/path.dart' as p;

class GitCommand extends Command {
  final Context context;

  @override
  final name = 'git';

  @override
  final description = 'Git management commands';

  GitCommand(this.context) {
    addSubcommand(GitInitCommand(context));
    addSubcommand(GitStatusCommand());
    addSubcommand(GitAddCommand());
    addSubcommand(GitCommitCommand());
    addSubcommand(GitPushCommand());
    addSubcommand(GitPullCommand());
    addSubcommand(GitBranchCommand());
    addSubcommand(GitCheckoutCommand());
    addSubcommand(GitLogCommand());
    addSubcommand(GitStashCommand());
    addSubcommand(GitResetCommand());
    addSubcommand(GitCleanCommand());
  }
}

Future<void> _runCmd(String cmd, List<String> args) async {
  final process = await Process.start(
    cmd,
    args,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}

Future<void> _runGit(List<String> args) async {
  await _runCmd('git', args);
}

Future<bool> _confirm(String prompt) async {
  stdout.write('$prompt [yes/no]: ');
  final response = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  return response == 'yes' || response == 'y';
}

class GitInitCommand extends Command {
  final Context context;

  @override
  final name = 'init';

  @override
  final description =
      'Initialize a GitHub repository for the current directory';

  GitInitCommand(this.context);

  @override
  Future<void> run() async {
    final dir = Directory.current.path;
    final projectName = p.basename(dir);

    logger.info('Initializing git repository');
    await _runGit(['init']);
    await _runGit(['add', '.']);
    await _runGit(['commit', '-m', 'Initial commit']);

    logger.info('Creating GitHub repository ${context.org}/$projectName');
    await _runCmd('gh', [
      'repo',
      'create',
      '${context.org}/$projectName',
      '--public',
      '--source=.',
      '--remote=origin',
    ]);

    logger.success('Repository ready: ${context.org}/$projectName');
  }
}

class GitStatusCommand extends Command {
  @override
  final name = 'status';

  @override
  final description = 'Show working tree status';

  @override
  Future<void> run() async => _runGit(['status']);
}

class GitAddCommand extends Command {
  @override
  final name = 'add';

  @override
  final description = 'Stage files (defaults to current directory)';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      await _runGit(['add', '.']);
      return;
    }
    await _runGit(['add', ...rest]);
  }
}

class GitCommitCommand extends Command {
  @override
  final name = 'commit';

  @override
  final description = 'Commit staged changes';

  GitCommitCommand() {
    argParser.addOption('message', abbr: 'm', help: 'Commit message');
  }

  @override
  Future<void> run() async {
    final message = argResults?['message'] as String?;
    if (message != null && message.trim().isNotEmpty) {
      await _runGit(['commit', '-m', message.trim()]);
      return;
    }
    stdout.write('Enter commit message: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    if (input.isEmpty) {
      stderr.writeln('Error: commit message is required.');
      exit(1);
    }
    await _runGit(['commit', '-m', input]);
  }
}

class GitPushCommand extends Command {
  @override
  final name = 'push';

  @override
  final description = 'Push commits (defaults to origin current branch)';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      await _runGit(['push', 'origin', 'HEAD']);
      return;
    }
    await _runGit(['push', ...rest]);
  }
}

class GitPullCommand extends Command {
  @override
  final name = 'pull';

  @override
  final description = 'Pull latest changes';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      await _runGit(['pull']);
      return;
    }
    await _runGit(['pull', ...rest]);
  }
}

class GitBranchCommand extends Command {
  @override
  final name = 'branch';

  @override
  final description = 'List or create branches';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      await _runGit(['branch']);
      return;
    }
    await _runGit(['branch', ...rest]);
  }
}

class GitCheckoutCommand extends Command {
  @override
  final name = 'checkout';

  @override
  final description = 'Checkout a branch or commit';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      stderr.writeln('Usage: learmond git checkout <branch-or-ref>');
      exit(64);
    }
    await _runGit(['checkout', ...rest]);
  }
}

class GitLogCommand extends Command {
  @override
  final name = 'log';

  @override
  final description = 'Show concise commit history';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      await _runGit(['log', '--oneline', '--graph', '--decorate', '-20']);
      return;
    }
    await _runGit(['log', ...rest]);
  }
}

class GitStashCommand extends Command {
  @override
  final name = 'stash';

  @override
  final description = 'Stash commands (defaults to stash push)';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      await _runGit(['stash', 'push']);
      return;
    }
    await _runGit(['stash', ...rest]);
  }
}

class GitResetCommand extends Command {
  @override
  final name = 'reset';

  @override
  final description = 'Reset operations';

  GitResetCommand() {
    addSubcommand(GitResetHardCommand());
  }
}

class GitResetHardCommand extends Command {
  @override
  final name = 'hard';

  @override
  final description = 'Run git reset --hard';

  @override
  Future<void> run() async {
    final ok = await _confirm(
      'This will permanently discard all tracked local changes. Continue?',
    );
    if (!ok) {
      stdout.writeln('Cancelled.');
      return;
    }
    await _runGit(['reset', '--hard']);
  }
}

class GitCleanCommand extends Command {
  @override
  final name = 'clean';

  @override
  final description = 'Clean operations';

  GitCleanCommand() {
    addSubcommand(GitCleanFdCommand());
  }
}

class GitCleanFdCommand extends Command {
  @override
  final name = 'fd';

  @override
  final description = 'Run git clean -fd';

  @override
  Future<void> run() async {
    final ok = await _confirm(
      'This will permanently remove untracked files and directories. Continue?',
    );
    if (!ok) {
      stdout.writeln('Cancelled.');
      return;
    }
    await _runGit(['clean', '-fd']);
  }
}
