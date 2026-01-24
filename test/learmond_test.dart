import 'dart:io';
import 'package:test/test.dart';
import 'package:learmond/domains/license/license_command.dart' as license_lib;

void main() {
  test('CLI help lists all top-level commands', () async {
    final expectedCommands = [
      'analyze',
      'build',
      'changelog',
      'clean',
      'create',
      'doctor',
      'flutter',
      'format',
      'fix',
      'install',
      'publish',
      'push',
      'repo',
      'test',
      'license',
    ];

    final future = Process.run('dart', [
      'run',
      'bin/learmond.dart',
      '--help',
    ], runInShell: true);
    final result = await future.timeout(Duration(seconds: 5));
    expect(
      result.exitCode,
      equals(0),
      reason: 'Help command failed: ${result.stderr}',
    );
    final out = (result.stdout as String) + (result.stderr as String);
    for (final cmd in expectedCommands) {
      expect(
        out,
        contains(cmd),
        reason: 'Help output does not list command: $cmd',
      );
    }
  });

  test('license generates file with specified type and author', () async {
    final tmp = await Directory.systemTemp.createTemp('learmond_license_test');
    try {
      // Use the generator directly to avoid depending on CLI working dir
      final orig = Directory.current;
      try {
        Directory.current = tmp.path;
        final generator = license_lib.LicenseCommand(
          'apache-2.0',
          'Test Author',
        );
        generator.execute();

        final file = File('${tmp.path}/LICENSE');
        expect(await file.exists(), isTrue);
        final content = await file.readAsString();
        expect(content, contains('Apache License'));
        expect(content, contains('Test Author'));
      } finally {
        Directory.current = orig.path;
      }
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('license rejects unsupported types', () async {
    final result = await Process.run('dart', [
      'run',
      'bin/learmond.dart',
      'license',
      '-t',
      'invalid-type',
      '-a',
      'X',
    ], runInShell: true);
    // Expect non-zero exit code for invalid type
    expect(result.exitCode, isNot(equals(0)));
  });
}
