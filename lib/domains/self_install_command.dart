import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/logger.dart';

class SelfInstallCommand extends Command {
  @override
  final name = 'install';

  @override
  final description = 'Compile the Dart CLI and install it to /usr/local/bin';

  @override
  Future<void> run() async {
    final exeName = 'learmond';
    final exePath = '${Directory.current.path}/bin/learmond.dart';

    logger.info('Running dart pub get...');
    final pubGet = await Process.run('dart', ['pub', 'get'], runInShell: true);

    if (pubGet.exitCode != 0) {
      stderr.write(pubGet.stderr);
      exit(pubGet.exitCode);
    }

    logger.info('Compiling Dart CLI...');
    final compile = await Process.run('dart', [
      'compile',
      'exe',
      exePath,
      '-o',
      exeName,
    ], runInShell: true);

    if (compile.exitCode != 0) {
      stderr.write(compile.stderr);
      exit(compile.exitCode);
    }

    logger.info('Moving binary to /usr/local/bin (requires sudo)...');
    final move = await Process.run('sudo', [
      'mv',
      exeName,
      '/usr/local/bin/',
    ], runInShell: true);

    if (move.exitCode != 0) {
      stderr.write(move.stderr);
      exit(move.exitCode);
    }

    // Determine homebrew tap path
    final tapPath = Platform.environment['LEARMOND_TAP_PATH'] ?? '${Directory.current.path}/homebrew-learmond';
    final tapDir = Directory(tapPath);
    if (await tapDir.exists()) {
      logger.info('Copying binary to Homebrew tap folder at $tapDir...');
      try {
        final sourceFile = File('/usr/local/bin/$exeName');
        final destFile = File('${tapDir.path}/$exeName');
        await sourceFile.copy(destFile.path);
      } catch (e) {
        stderr.writeln('Failed to copy binary to Homebrew tap folder: $e');
        exit(1);
      }

      logger.info('Computing SHA256 checksum for the binary...');
      String sha256Hex;
      try {
        final binaryBytes = await File('${tapDir.path}/$exeName').readAsBytes();
        final sha256Digest = sha256.convert(binaryBytes);
        sha256Hex = sha256Digest.toString();
        logger.info('SHA256: $sha256Hex');
      } catch (e) {
        stderr.writeln('Failed to compute SHA256 checksum: $e');
        exit(1);
      }

      // Update learmond.rb formula file with new SHA256
      final formulaFile = File('${tapDir.path}/learmond.rb');
      if (await formulaFile.exists()) {
        try {
          final lines = await formulaFile.readAsLines();
          final updatedLines = lines.map((line) {
            if (line.trim().startsWith('sha256 ')) {
              return "  sha256 '$sha256Hex'";
            }
            return line;
          }).toList();
          await formulaFile.writeAsString(updatedLines.join('\n'));
          logger.info('Updated learmond.rb formula with new SHA256 checksum.');
        } catch (e) {
          stderr.writeln('Failed to update learmond.rb formula file: $e');
          exit(1);
        }
      } else {
        logger.info('Formula file learmond.rb not found in Homebrew tap folder, skipping formula update.');
      }

      // Delete the binary from the tap folder
      try {
        final fileToDelete = File('${tapDir.path}/$exeName');
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
        }
      } catch (e) {
        stderr.writeln('Failed to delete binary from Homebrew tap folder: $e');
        exit(1);
      }
    } else {
      logger.info('Homebrew tap folder not found at $tapDir, skipping copy and SHA256 computation.');
    }

    logger.success(
      'Installed successfully! You can now run `learmond` globally.',
    );
  }
}
