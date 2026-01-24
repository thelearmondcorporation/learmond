import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

class GithubPushCommand extends Command {
  @override
  final String name = 'push';
  @override
  final String description =
      'Stage, commit, and push changes to the current branch on origin.';

  GithubPushCommand();

  @override
  Future<void> run() async {
    // 1. Detect git repository
    final isGitRepo = await _isGitRepository();
    if (!isGitRepo) {
      stderr.writeln(
        'Error: Not a git repository (or any of the parent directories).',
      );
      return;
    }

    // 2. Detect changes
    final statusResult = await Process.run('git', ['status', '--porcelain']);
    if (statusResult.exitCode != 0) {
      stderr.add(
        statusResult.stderr as List<int>? ??
            utf8.encode('Failed to run git status.'),
      );
      return;
    }
    final changedLines = (statusResult.stdout as String)
        .trim()
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();
    if (changedLines.isEmpty) {
      stdout.writeln('No changes to commit.');
      return;
    }

    // Parse changed files and their statuses
    final List<String> changedFiles = [];
    final List<String> changeDescriptions = [];
    final Map<String, String> modifiedFileDetails = {};

    for (var line in changedLines) {
      // line format: XY filename (possibly with rename info)
      // We consider the first character (index 0) or second character (index 1) to determine status
      String statusChar = line[0];
      if (statusChar == ' ') {
        statusChar = line[1];
      }
      String type;
      switch (statusChar) {
        case 'M':
          type = 'modified';
          break;
        case 'A':
          type = 'added';
          break;
        case 'D':
          type = 'deleted';
          break;
        case 'R':
          type = 'renamed';
          break;
        case 'C':
          type = 'copied';
          break;
        case 'U':
          type = 'updated but unmerged';
          break;
        default:
          type = 'changed';
      }
      // filename starts at index 3, but for rename, it's "R100 oldfile -> newfile"
      String filenamePart = line.substring(3).trim();
      String filename;
      if (type == 'renamed') {
        // extract new filename after '->'
        final parts = filenamePart.split('->');
        filename = parts.length > 1 ? parts[1].trim() : filenamePart;
      } else {
        filename = filenamePart;
      }
      changedFiles.add(filename);
      changeDescriptions.add('$filename ($type)');
    }

    // For modified files, get detailed modification info
    final modifiedFiles = <String>[];
    for (var desc in changeDescriptions) {
      if (desc.contains('(modified)')) {
        final filename = desc.substring(0, desc.indexOf(' (modified)'));
        modifiedFiles.add(filename);
      }
    }

    if (modifiedFiles.isNotEmpty) {
      // Use git diff --name-status HEAD to get modification details
      final diffResult = await Process.run('git', [
        'diff',
        '--name-status',
        'HEAD',
      ]);
      if (diffResult.exitCode == 0) {
        final diffLines = (diffResult.stdout as String).trim().split('\n');
        for (var modFile in modifiedFiles) {
          for (var diffLine in diffLines) {
            // diffLine format: <status>\t<file>
            if (diffLine.endsWith('\t$modFile')) {
              final parts = diffLine.split('\t');
              if (parts.length >= 2) {
                final diffStatus = parts[0];
                String detail = '';
                switch (diffStatus) {
                  case 'M':
                    detail = 'content modified';
                    break;
                  case 'T':
                    detail = 'mode changed';
                    break;
                  case 'U':
                    detail = 'unmerged';
                    break;
                  default:
                    detail = 'modified';
                }
                modifiedFileDetails[modFile] = detail;
              }
              break;
            }
          }
        }
      }
    }

    // 3. Stage all changes
    final addRes = await _runGit(['add', '.']);
    if (addRes != 0) exit(addRes);

    // 4. Generate auto commit message
    final now = DateTime.now().toLocal();
    final timestamp = now.toIso8601String();

    final List<String> detailedDescriptions = [];
    for (var desc in changeDescriptions) {
      if (desc.contains('(modified)')) {
        final filename = desc.substring(0, desc.indexOf(' (modified)'));
        final detail = modifiedFileDetails[filename];
        if (detail != null) {
          detailedDescriptions.add('$filename (modified: $detail)');
          continue;
        }
      }
      detailedDescriptions.add(desc);
    }

    String autoMessage =
        'Auto commit on $timestamp: ${changedFiles.length} file(s) changed: ${detailedDescriptions.join(', ')}';

    // 5. Prompt for optional message
    stdout.write('Enter optional commit message (press Enter to skip): ');
    String? extraMessage = stdin.readLineSync(encoding: utf8)?.trim();
    if (extraMessage != null && extraMessage.isNotEmpty) {
      autoMessage = '$autoMessage - $extraMessage';
    }

    // 6. Commit changes
    final commitRes = await _runGit(['commit', '-m', autoMessage]);
    if (commitRes != 0) exit(commitRes);

    // 7. Push to origin and current branch
    final branch = await _getCurrentBranch();
    if (branch == null) {
      stderr.writeln('Error: Failed to determine current branch.');
      exit(1);
    }
    final pushRes = await _runGit(['push', 'origin', branch]);
    if (pushRes != 0) exit(pushRes);

    // Completed successfully
    return;
  }

  Future<bool> _isGitRepository() async {
    final result = await Process.run('git', [
      'rev-parse',
      '--is-inside-work-tree',
    ]);
    return result.exitCode == 0 && (result.stdout as String).trim() == 'true';
  }

  Future<String?> _getCurrentBranch() async {
    final result = await Process.run('git', [
      'rev-parse',
      '--abbrev-ref',
      'HEAD',
    ]);
    if (result.exitCode != 0) return null;
    final branch = (result.stdout as String).trim();
    return branch.isNotEmpty ? branch : null;
  }

  Future _runGit(List<String> args) async {
    final process = await Process.start('git', args);
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
    return await process.exitCode;
  }
}
