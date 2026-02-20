import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import '../core/logger.dart';

class SelfInstallCommand extends Command {
  @override
  final name = 'install';

  @override
  final description =
      'Compile the Dart CLI and install it globally with OS-aware install paths';

  @override
  Future<void> run() async {
    final exeName = Platform.isWindows ? 'learmond.exe' : 'learmond';
    final exePath = '${Directory.current.path}/bin/learmond.dart';

    logger.info('Running flutter pub get...');
    final pubGet = await Process.run(
      'flutter',
      ['pub', 'get'],
      runInShell: true,
    );

    if (pubGet.exitCode != 0) {
      stderr.write(pubGet.stderr);
      exit(pubGet.exitCode);
    }

    logger.info('Compiling Learmond CLI with Flutter...');
    final compile = await Process.run(
      'flutter',
      [
        'dart',
        'compile',
        'exe',
        exePath,
        '-o',
        exeName,
      ],
      runInShell: true,
    );

    if (compile.exitCode != 0) {
      stderr.write(compile.stderr);
      exit(compile.exitCode);
    }

    final installTarget = await _resolveInstallTarget(exeName);
    logger.info(
      'Installing binary for ${installTarget.platformLabel} at ${installTarget.targetPath}',
    );
    await _installBinary(exeName, installTarget);

    // New logic: copy binary to bin/DEBIAN/usr/local/bin
    final debianBinDir = Directory('${Directory.current.path}/bin/DEBIAN/usr/local/bin');
    if (!await debianBinDir.exists()) {
      await debianBinDir.create(recursive: true);
    }
    final sourceFile = File(installTarget.targetPath);
    final destFile = File('${debianBinDir.path}/$exeName');
    try {
      await sourceFile.copy(destFile.path);
      logger.info('Copied binary to ${destFile.path}');
    } catch (e) {
      stderr.writeln('Failed to copy binary to DEBIAN folder: $e');
      exit(1);
    }

    // Determine homebrew tap path
    final tapPath = Platform.environment['LEARMOND_TAP_PATH'] ??
        '${Directory.current.path}/homebrew-learmond';
    final tapDir = Directory(tapPath);
    if (Platform.isMacOS && await tapDir.exists()) {
      logger.info('Copying binary to Homebrew tap folder at $tapDir...');
      try {
        final sourceFile = File(installTarget.targetPath);
        final destFile = File('${tapDir.path}/$exeName');
        await sourceFile.copy(destFile.path);
      } catch (e) {
        stderr.writeln('Failed to copy binary to Homebrew tap folder: $e');
        exit(1);
      }
    }

    // Compute SHA256 checksum and update formula if tap folder exists
    if (Platform.isMacOS && await tapDir.exists()) {
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
      }
      // Also update Chocolatey install script checksum if present
      final chocoPath = Platform.environment['LEARMOND_CHOCOLATEY_PATH'] ??
          '${Directory.current.path}/packaging/chocolatey';
      final chocoFile = File('$chocoPath/tools/chocolateyInstall.ps1');
      if (await chocoFile.exists()) {
        try {
          final lines = await chocoFile.readAsLines();
          final updated = lines.map((line) {
            final t = line.trimLeft();
            if (t.startsWith(r"$checksum") || t.startsWith(r"$checksum =") || t.startsWith(r"$checksum = '")) {
              return "\$checksum = '$sha256Hex'";
            }
            return line;
          }).toList();
          await chocoFile.writeAsString(updated.join('\n'));
          logger.info('Updated chocolateyInstall.ps1 with new SHA256 checksum.');
        } catch (e) {
          stderr.writeln('Failed to update chocolateyInstall.ps1: $e');
          exit(1);
        }
      }
    }

    logger.success(
      'Installed successfully! You can now run `learmond` globally.',
    );
  }

  Future<_InstallTarget> _resolveInstallTarget(String exeName) async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          Directory.current.path;
      final targetDir = Directory(
        '$userProfile\\AppData\\Local\\Programs\\Learmond\\bin',
      );
      return _InstallTarget(
        platformLabel: 'Windows',
        targetDir: targetDir.path,
        targetPath: '${targetDir.path}\\$exeName',
        useSudo: false,
      );
    }

    if (Platform.isMacOS) {
      return _InstallTarget(
        platformLabel: 'macOS',
        targetDir: '/usr/local/bin',
        targetPath: '/usr/local/bin/$exeName',
        useSudo: true,
      );
    }

    if (Platform.isLinux) {
      final distro = await _linuxDistroLabel();
      return _InstallTarget(
        platformLabel: distro,
        targetDir: '/usr/local/bin',
        targetPath: '/usr/local/bin/$exeName',
        useSudo: true,
      );
    }

    return _InstallTarget(
      platformLabel: 'Unknown',
      targetDir: '/usr/local/bin',
      targetPath: '/usr/local/bin/$exeName',
      useSudo: true,
    );
  }

  Future<String> _linuxDistroLabel() async {
    try {
      final osRelease = File('/etc/os-release');
      if (await osRelease.exists()) {
        final content = await osRelease.readAsString();
        if (content.toLowerCase().contains('ubuntu')) {
          return 'Ubuntu/Linux';
        }
      }
    } catch (_) {}
    return 'Linux';
  }

  Future<void> _installBinary(String exeName, _InstallTarget target) async {
    if (target.useSudo) {
      final mkdir = await Process.run(
        'sudo',
        ['mkdir', '-p', target.targetDir],
        runInShell: true,
      );
      if (mkdir.exitCode != 0) {
        stderr.write(mkdir.stderr);
        exit(mkdir.exitCode);
      }

      final move = await Process.run(
        'sudo',
        ['mv', exeName, target.targetPath],
        runInShell: true,
      );
      if (move.exitCode != 0) {
        stderr.write(move.stderr);
        exit(move.exitCode);
      }

      final chmod = await Process.run(
        'sudo',
        ['chmod', '+x', target.targetPath],
        runInShell: true,
      );
      if (chmod.exitCode != 0) {
        stderr.write(chmod.stderr);
        exit(chmod.exitCode);
      }
      return;
    }

    final dir = Directory(target.targetDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final dest = File(target.targetPath);
    await File(exeName).copy(dest.path);
  }
}

class _InstallTarget {
  final String platformLabel;
  final String targetDir;
  final String targetPath;
  final bool useSudo;

  _InstallTarget({
    required this.platformLabel,
    required this.targetDir,
    required this.targetPath,
    required this.useSudo,
  });
}

class SelfReinstallCommand extends Command {
  @override
  final name = 'reinstall';

  @override
  final description = 'Compile the Dart CLI executable (compile-only, no install)';

  @override
  Future<void> run() async {
    final exeName = 'learmond';
    final exePath = '${Directory.current.path}/bin/learmond.dart';

    // Determine homebrew tap path
    final tapPath =
        Platform.environment['LEARMOND_TAP_PATH'] ?? '${Directory.current.path}/homebrew-learmond';
    final tapDir = Directory(tapPath);

    // Remove existing global binary
    logger.info('Removing existing global binary /usr/local/bin/$exeName (requires sudo)...');
    try {
      final rm = await Process.run('sudo', ['rm', '-f', '/usr/local/bin/$exeName'], runInShell: true);
      if (rm.exitCode != 0) {
        stderr.writeln(rm.stderr);
      }
    } catch (e) {
      stderr.writeln('Failed to remove existing binary: $e');
    }

    // Remove copy in Homebrew tap if present
    if (await tapDir.exists()) {
      try {
        final tapBin = File('${tapDir.path}/$exeName');
        if (await tapBin.exists()) {
          logger.info('Removing existing tap binary at ${tapBin.path}');
          await tapBin.delete();
        }
      } catch (e) {
        stderr.writeln('Failed to remove tap binary: $e');
      }
    }

    // Simplified reinstall: only compile the executable as requested
    logger.info('Running flutter pub get...');
    final pubGet = await Process.run(
      'flutter',
      ['pub', 'get'],
      runInShell: true,
    );
    if (pubGet.exitCode != 0) {
      stderr.write(pubGet.stderr);
      exit(pubGet.exitCode);
    }

    logger.info('Compiling Learmond CLI with Flutter...');
    final compile = await Process.run(
      'flutter',
      [
        'dart',
        'compile',
        'exe',
        exePath,
        '-o',
        exeName,
      ],
      runInShell: true,
    );

    if (compile.exitCode != 0) {
      stderr.write(compile.stderr);
      exit(compile.exitCode);
    }

    logger.success('Compiled successfully to $exeName. You can move it to /usr/local/bin if desired.');
  }
}
