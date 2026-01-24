import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';

class CreateCommand extends Command {
  @override
  final name = 'create';
  @override
  final description =
      'Create a new project for Flutter, React Native, Ruby, or NPM and move into the project directory.';

  CreateCommand() {
    argParser
      ..addFlag(
        'package',
        abbr: 'p',
        negatable: false,
        help: 'Create a Flutter package instead of an app (only for Flutter).',
      )
      ..addOption(
        'org',
        help: 'Set the organization (e.g., com.example) (only for Flutter)',
      )
      ..addOption(
        'type',
        abbr: 't',
        allowed: ['flutter', 'react-native', 'ruby', 'npm'],
        defaultsTo: 'flutter',
        help:
          'Specify the type of project to create: flutter, react-native (uses Expo, includes web), ruby, npm.',
      )
      ..addFlag(
        'cd',
        defaultsTo: true,
        help: 'Print command to switch to the new directory after creation.',
      );
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      print('Error: You must specify a project name.');
      print(
        'Usage: learmond create <name> [--type flutter|react-native|ruby|npm] [--package] [--org com.example]',
      );
      return;
    }

    final name = argResults!.rest[0];
    final type = argResults!['type'] as String;
    final shouldCd = argResults!['cd'] as bool;

    if (type == 'flutter') {
      final isPackage = argResults!['package'] as bool;
      final org = argResults!['org'] as String?;
      final args = ['create', name];
      if (isPackage) args.add('--template=package');
      if (org != null) args.addAll(['--org', org]);

      print('Running: flutter ${args.join(' ')}');
      final result = await Process.run('flutter', args);

      stdout.write(result.stdout);
      stderr.write(result.stderr);

      if (result.exitCode != 0) {
        print('Flutter create failed with exit code ${result.exitCode}');
        exit(result.exitCode);
      }

      print('\nFlutter project "$name" created successfully.');
    } else if (type == 'react-native') {
      // Use Expo to create a React Native project; Expo includes web support by default.
      print('Running: npx create-expo-app $name');
      final result = await Process.run('npx', ['create-expo-app', name]);

      stdout.write(result.stdout);
      stderr.write(result.stderr);

      if (result.exitCode != 0) {
        print('Expo create failed with exit code ${result.exitCode}');
        exit(result.exitCode);
      }

      // Ensure dependencies are installed (safe no-op if already done by the tool).
      print('Ensuring dependencies are installed in $name...');
      final installResult = await Process.run('npm', ['install'], workingDirectory: name);
      stdout.write(installResult.stdout);
      stderr.write(installResult.stderr);
      if (installResult.exitCode != 0) {
        print('npm install failed with exit code ${installResult.exitCode}');
        // don't exit; project was created, but warn the user
      }

      // Update package.json scripts to include convenient web/start scripts.
      try {
        final pkgFile = File('$name/package.json');
        if (await pkgFile.exists()) {
          final content = await pkgFile.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final scripts = (data['scripts'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          scripts.putIfAbsent('web', () => 'expo start --web');
          scripts.putIfAbsent('start', () => 'expo start');
          data['scripts'] = scripts;
          final encoder = JsonEncoder.withIndent('  ');
          await pkgFile.writeAsString(encoder.convert(data));
          print('Added npm scripts: "web" and "start" to package.json');
        }
      } catch (e) {
        print('Warning: failed to update package.json scripts: $e');
      }

      print('\nExpo project "$name" created successfully with web support.');
    } else if (type == 'ruby') {
      print('Running: bundle gem $name');
      final result = await Process.run('bundle', ['gem', name]);

      stdout.write(result.stdout);
      stderr.write(result.stderr);

      if (result.exitCode != 0) {
        print('Ruby gem create failed with exit code ${result.exitCode}');
        exit(result.exitCode);
      }

      print('\nRuby gem "$name" created successfully.');
    } else if (type == 'npm') {
      print('Running: npm init -y in $name directory');
      final createDirResult = await Process.run('mkdir', [name]);
      if (createDirResult.exitCode != 0) {
        print(
          'Failed to create directory "$name" with exit code ${createDirResult.exitCode}',
        );
        exit(createDirResult.exitCode);
      }
      final result = await Process.run('npm', [
        'init',
        '-y',
      ], workingDirectory: name);

      stdout.write(result.stdout);
      stderr.write(result.stderr);

      if (result.exitCode != 0) {
        print('NPM project create failed with exit code ${result.exitCode}');
        exit(result.exitCode);
      }

      print('\nNPM project "$name" created successfully.');
    } else {
      print('Unsupported project type: $type');
      return;
    }

    // Suggest changing directory
    if (shouldCd) {
      print('\nNext steps:');
      print('  cd $name');
      if (type == 'flutter') {
        print('  flutter pub get');
      } else if (type == 'react-native') {
        print('  npm install');
        print('  npx expo start --web # start web dev server');
        print('  npx expo start # start dev server for all platforms');
      } else if (type == 'ruby') {
        print('  bundle install');
      } else if (type == 'npm') {
        print('  npm install');
      }
      print('Now you are ready to start developing!');
    }
  }
}
