import 'dart:io';
import 'package:args/command_runner.dart';

class ChangelogCommand extends Command {
  @override
  final name = 'changelog';
  @override
  final description =
      'Generate or update the project CHANGELOG.md and README.md.';

  @override
  Future<void> run() async {
    final currentDir = Directory.current;
    print('Current project directory: ${currentDir.path}');

    final changelogFile = File('${currentDir.path}/CHANGELOG.md');
    final readmeFile = File('${currentDir.path}/README.md');

    // Get the latest git tag (version)
    final latestTagResult = await Process.run('git', [
      'describe',
      '--tags',
      '--abbrev=0',
    ]);
    String latestVersion = 'Unreleased';
    if (latestTagResult.exitCode == 0) {
      latestVersion = (latestTagResult.stdout as String).trim();
    } else {
      print('No git tags found, using "Unreleased" as version.');
    }

    // Get commits since the latest tag or all commits if no tag
    List<String> commits = [];
    if (latestVersion != 'Unreleased') {
      final commitsResult = await Process.run('git', [
        'log',
        '$latestVersion..HEAD',
        '--pretty=format:%s',
      ]);
      if (commitsResult.exitCode == 0) {
        commits = (commitsResult.stdout as String)
            .split('\n')
            .where((c) => c.trim().isNotEmpty)
            .toList();
      }
    } else {
      final commitsResult = await Process.run('git', [
        'log',
        '--pretty=format:%s',
      ]);
      if (commitsResult.exitCode == 0) {
        commits = (commitsResult.stdout as String)
            .split('\n')
            .where((c) => c.trim().isNotEmpty)
            .toList();
      }
    }

    if (commits.isEmpty) {
      print('No new commits found to update CHANGELOG.md');
      return;
    }

    final newVersion = latestVersion == 'Unreleased'
        ? 'v0.1.0'
        : _incrementVersion(latestVersion);

    final changelogEntry = StringBuffer();
    changelogEntry.writeln('## $newVersion\n');
    for (final commit in commits) {
      changelogEntry.writeln('- $commit');
    }
    changelogEntry.writeln();

    String existingChangelog = '';
    if (await changelogFile.exists()) {
      existingChangelog = await changelogFile.readAsString();
    }

    final updatedChangelog = StringBuffer();
    updatedChangelog.writeln(changelogEntry.toString());
    updatedChangelog.writeln(existingChangelog);

    // Write or update CHANGELOG.md
    if (await changelogFile.exists()) {
      // Prepend new entry to existing changelog
      final existingChangelog = await changelogFile.readAsString();
      final updatedChangelogExisting = StringBuffer();
      updatedChangelogExisting.writeln(changelogEntry.toString());
      updatedChangelogExisting.writeln(existingChangelog);
      await changelogFile.writeAsString(updatedChangelogExisting.toString());
      print('CHANGELOG.md updated with version $newVersion');
    } else {
      // Create a new changelog file
      final newChangelog = StringBuffer();
      newChangelog.writeln('# Changelog\n');
      newChangelog.writeln(
        'All notable changes to this project will be documented in this file.',
      );
      newChangelog.writeln();
      newChangelog.writeln(changelogEntry.toString());
      await changelogFile.writeAsString(newChangelog.toString());
      print('CHANGELOG.md created with version $newVersion');
    }

    // Only generate README if it does not already exist. If it exists, skip modifications.
    if (await readmeFile.exists()) {
      print('README.md exists; skipping README generation or updates.');
    } else {
      // Create a minimal README with version and changelog summary
      final changelogSummary = commits.map((c) => '- $c').join('\n');
      final newReadmeContent =
          '''# Project

Latest Version: $newVersion

## Changelog Summary
$changelogSummary

''';
      await readmeFile.writeAsString(newReadmeContent);
      print('README.md created with latest version and changelog summary');
    }
  }

  String _incrementVersion(String version) {
    final versionPattern = RegExp(r'v?(\d+)\.(\d+)\.(\d+)');
    final match = versionPattern.firstMatch(version);
    if (match == null) return 'v0.1.0';
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    return 'v$major.$minor.${patch + 1}';
  }
}
