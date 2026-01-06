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

    await changelogFile.writeAsString(updatedChangelog.toString());
    print('CHANGELOG.md updated with version $newVersion');

    if (await readmeFile.exists()) {
      final readmeContent = await readmeFile.readAsString();
      final newReadmeContent = _updateReadme(
        readmeContent,
        newVersion,
        commits,
      );
      await readmeFile.writeAsString(newReadmeContent);
      print('README.md updated with latest version and changelog summary');
    } else {
      print('README.md not found; skipping update.');
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

  String _updateReadme(String content, String version, List<String> commits) {
    final versionPattern = RegExp(r'(Latest Version: )v?\d+\.\d+\.\d+');
    final newVersionLine = 'Latest Version: $version';

    String updatedContent;
    if (versionPattern.hasMatch(content)) {
      updatedContent = content.replaceAll(versionPattern, newVersionLine);
    } else {
      updatedContent = '$newVersionLine\n$content';
    }

    final changelogSummary = commits.map((c) => '- $c').join('\n');
    final changelogMarkerStart = '';
    final changelogMarkerEnd = '';
    final changelogSection =
        '$changelogMarkerStart\n$changelogSummary\n$changelogMarkerEnd';

    if (updatedContent.contains(changelogMarkerStart) &&
        updatedContent.contains(changelogMarkerEnd)) {
      final pattern = RegExp(
        '$changelogMarkerStart[\\s\\S]*?$changelogMarkerEnd',
      );
      updatedContent = updatedContent.replaceAll(pattern, changelogSection);
    } else {
      updatedContent = '$changelogSection\n\n$updatedContent';
    }

    return updatedContent;
  }
}
