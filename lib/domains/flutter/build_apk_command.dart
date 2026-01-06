import 'dart:io';
import 'package:args/command_runner.dart';

class FlutterBuildApkCommand extends Command {
  @override
  final name = 'apk';
  @override
  final description = 'Build and install release APK on an Android emulator';

  @override
  Future<void> run() async {
    print('Checking for running Android emulators...');

    final adbResult = await Process.run('adb', ['devices']);
    if (adbResult.exitCode != 0) {
      print('Failed to run adb:');
      print(adbResult.stderr);
      return;
    }

    final lines = (adbResult.stdout as String).split('\n').skip(1).toList();
    String? emulatorId;
    for (var line in lines) {
      if (line.trim().isNotEmpty &&
          line.contains('device') &&
          line.contains('emulator')) {
        emulatorId = line.split('\t').first.trim();
        break;
      }
    }

    if (emulatorId == null) {
      print('No running emulator found. Launching default emulator...');
      final avdListResult = await Process.run('emulator', ['-list-avds']);
      if (avdListResult.exitCode != 0) {
        print('Failed to list Android virtual devices:');
        print(avdListResult.stderr);
        return;
      }

      final avds = (avdListResult.stdout as String)
          .split('\n')
          .where((s) => s.isNotEmpty)
          .toList();
      if (avds.isEmpty) {
        print('No AVDs available. Create one with `avdmanager`.');
        return;
      }

      final defaultAvd = avds.first;
      print('Starting emulator $defaultAvd...');
      Process.start('emulator', ['-avd', defaultAvd], runInShell: true);
      print('Waiting for emulator to start...');
      await Process.run('adb', ['wait-for-device']);
      emulatorId = 'emulator-5554';
    }

    print('Building release APK...');
    final buildResult = await Process.run('flutter', [
      'build',
      'apk',
      '--release',
    ], runInShell: true);
    if (buildResult.exitCode != 0) {
      print('Failed to build APK:');
      print(buildResult.stderr);
      return;
    }

    print('Installing APK on emulator $emulatorId...');
    final apkPathResult = await Process.run('bash', [
      '-c',
      'find build/app/outputs/flutter-apk -name "*.apk" | head -n 1',
    ]);
    final apkPath = (apkPathResult.stdout as String).trim();
    if (apkPath.isEmpty) {
      print('Could not find generated APK.');
      return;
    }

    final installResult = await Process.run('adb', [
      '-s',
      emulatorId,
      'install',
      '-r',
      apkPath,
    ]);
    if (installResult.exitCode != 0) {
      print('Failed to install APK:');
      print(installResult.stderr);
      return;
    }

    print('APK installed successfully on $emulatorId.');
  }
}
