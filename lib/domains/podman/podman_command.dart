import 'dart:io';

import 'package:args/command_runner.dart';

class PodmanCommand extends Command {
  @override
  final name = 'podman';

  @override
  final description =
      'Build, manage, or view logs of the Podman container for the project.';

  @override
  String get usage {
    // Compose custom usage with subcommands section
    return '''
Usage: learmond podman [options] <subcommand>

$description

Options:
${argParser.usage}

Subcommands:
  start       Start the Podman VM
  stop        Stop the Podman VM
  run         Run the Podman image
  reset       Reset the Podman VM
  clean       Clean broken Podman state (no VM init/start)
  bind mount  Run container with bind mount
  ps          List running containers
  exec        Open interactive bash in a container
  storage     Show Podman storage usage
  prune       Remove all images, containers, and volumes (dangerous!)
''';
  }

  PodmanCommand() {
    argParser.addOption(
      'image',
      abbr: 'i',
      help:
          'Name of the Podman image to build/run. You will be prompted if not provided.',
    );
    argParser.addFlag(
      'logs',
      abbr: 'l',
      negatable: false,
      help: 'Show logs for the last built container image.',
    );
  }

  @override
  Future<void> run() async {
    final args = argResults?.rest ?? [];

    Future<void> ensurePodmanRunning() async {
      final ping = await Process.run('podman', ['info']);
      if (ping.exitCode == 0) return;

      stdout.writeln(
        'Podman engine not running. Initializing and starting Podman machine...',
      );

      // Try starting first (machine may already exist)
      final startResult = await Process.run('podman', [
        'machine',
        'start',
        'podman-machine-default',
      ]);

      if (startResult.exitCode == 0) return;

      // If start failed, initialize then start
      final initResult = await Process.run('podman', [
        'machine',
        'init',
        '--cpus',
        '4',
        '--memory',
        '4096',
        '--disk-size',
        '20',
      ]);
      stdout.write(initResult.stdout);
      stderr.write(initResult.stderr);

      if (initResult.exitCode != 0) {
        stderr.writeln(
          'Error: podman machine init failed with exit code ${initResult.exitCode}.',
        );
        exit(initResult.exitCode);
      }

      final startResult2 = await Process.run('podman', [
        'machine',
        'start',
        'podman-machine-default',
      ]);
      stdout.write(startResult2.stdout);
      stderr.write(startResult2.stderr);

      if (startResult2.exitCode != 0) {
        stderr.writeln(
          'Error: podman machine start failed with exit code ${startResult2.exitCode}.',
        );
        exit(startResult2.exitCode);
      }
    }

    if (args.isNotEmpty) {
      final subcommand = args.first.toLowerCase();

      if (subcommand == 'storage') {
        // Show Podman storage usage
        final result = await Process.run('podman', ['system', 'df']);
        stdout.write(result.stdout);
        stderr.write(result.stderr);
        exit(result.exitCode);
      } else if (subcommand == 'prune') {
        // Get all container IDs and stop & remove them if any exist.
        final psResult = await Process.run('podman', ['ps', '-aq']);
        if (psResult.exitCode != 0) {
          stderr.write(psResult.stderr);
          exit(psResult.exitCode);
        }
        final containerIds = (psResult.stdout as String)
            .trim()
            .split('\n')
            .where((id) => id.trim().isNotEmpty)
            .toList();
        if (containerIds.isNotEmpty) {
          // Stop all containers
          final stopProcess = await Process.start('podman', ['stop', ...containerIds]);
          await stopProcess.stdout.pipe(stdout);
          await stopProcess.stderr.pipe(stderr);
          final stopExit = await stopProcess.exitCode;
          if (stopExit != 0) {
            stderr.writeln('Error: podman stop failed with exit code $stopExit.');
            exit(stopExit);
          }
          // Remove all containers
          final rmProcess = await Process.start('podman', ['rm', '-f', ...containerIds]);
          await rmProcess.stdout.pipe(stdout);
          await rmProcess.stderr.pipe(stderr);
          final rmExit = await rmProcess.exitCode;
          if (rmExit != 0) {
            stderr.writeln('Error: podman rm failed with exit code $rmExit.');
            exit(rmExit);
          }
        }
        // Get all image IDs and remove them if any exist.
        final imagesResult = await Process.run('podman', ['images', '-q']);
        if (imagesResult.exitCode != 0) {
          stderr.write(imagesResult.stderr);
          exit(imagesResult.exitCode);
        }
        final imageIds = (imagesResult.stdout as String)
            .trim()
            .split('\n')
            .where((id) => id.trim().isNotEmpty)
            .toList();
        if (imageIds.isNotEmpty) {
          final rmiProcess = await Process.start('podman', ['rmi', '-f', ...imageIds]);
          await rmiProcess.stdout.pipe(stdout);
          await rmiProcess.stderr.pipe(stderr);
          final rmiExit = await rmiProcess.exitCode;
          if (rmiExit != 0) {
            stderr.writeln('Error: podman rmi failed with exit code $rmiExit.');
            exit(rmiExit);
          }
        }
        // Prune all remaining unused data, including volumes
        final pruneProcess = await Process.start(
          'podman',
          ['system', 'prune', '-a', '-f', '--volumes'],
        );
        await pruneProcess.stdout.pipe(stdout);
        await pruneProcess.stderr.pipe(stderr);
        final exitCode = await pruneProcess.exitCode;
        exit(exitCode);
      } else if (subcommand == 'start') {
        final result = await Process.run('podman', [
          'machine',
          'start',
          'podman-machine-default',
        ]);
        stdout.write(result.stdout);
        stderr.write(result.stderr);
        exit(result.exitCode);
      } else if (subcommand == 'stop') {
        final result = await Process.run('podman', [
          'machine',
          'stop',
          'podman-machine-default',
        ]);
        stdout.write(result.stdout);
        stderr.write(result.stderr);
        exit(result.exitCode);
      } else if (subcommand == 'reset') {
        // Check if podman-machine-default exists
        final lsResult = await Process.run('podman', [
          'machine',
          'list',
          '--format',
          '{{.Name}}',
        ]);
        if (lsResult.exitCode != 0) {
          stderr.writeln('Error listing Podman machines: ${lsResult.stderr}');
          exit(lsResult.exitCode);
        }

        final machines = (lsResult.stdout as String).trim().split('\n');
        final machineExists = machines.contains('podman-machine-default');

        if (machineExists) {
          final steps = [
            ['podman', 'machine', 'stop', 'podman-machine-default'],
            ['podman', 'machine', 'rm', '-f', 'podman-machine-default'],
            [
              'podman',
              'machine',
              'init',
              '--cpus',
              '4',
              '--memory',
              '4096',
              '--disk-size',
              '20',
            ],
            ['podman', 'machine', 'start', 'podman-machine-default'],
            ['podman', 'ps'],
          ];

          for (final step in steps) {
            stdout.writeln('Running command: ${step.join(' ')}');
            final result = await Process.run(step[0], step.sublist(1));
            stdout.write(result.stdout);
            stderr.write(result.stderr);
            if (result.exitCode != 0) {
              stderr.writeln(
                'Error: command "${step.join(' ')}" failed with exit code ${result.exitCode}.',
              );
              exit(result.exitCode);
            }
          }
        } else {
          stdout.writeln(
            'Podman machine "podman-machine-default" does not exist. Initializing and starting a new machine.',
          );
          final initResult = await Process.run('podman', [
            'machine',
            'init',
            '--cpus',
            '4',
            '--memory',
            '4096',
            '--disk-size',
            '20',
          ]);
          stdout.write(initResult.stdout);
          stderr.write(initResult.stderr);
          if (initResult.exitCode != 0) {
            stderr.writeln(
              'Error: command "podman machine init" failed with exit code ${initResult.exitCode}.',
            );
            exit(initResult.exitCode);
          }

          final startResult = await Process.run('podman', [
            'machine',
            'start',
            'podman-machine-default',
          ]);
          stdout.write(startResult.stdout);
          stderr.write(startResult.stderr);
          if (startResult.exitCode != 0) {
            stderr.writeln(
              'Error: command "podman machine start" failed with exit code ${startResult.exitCode}.',
            );
            exit(startResult.exitCode);
          }

          final psResult = await Process.run('podman', ['ps']);
          stdout.write(psResult.stdout);
          stderr.write(psResult.stderr);
          if (psResult.exitCode != 0) {
            stderr.writeln(
              'Error: command "podman ps" failed with exit code ${psResult.exitCode}.',
            );
            exit(psResult.exitCode);
          }
        }
        exit(0);
      } else if (subcommand == 'bind' &&
          args.length > 1 &&
          args[1].toLowerCase() == 'mount') {
        String? image = argResults?['image'];

        if (image == null || image.trim().isEmpty) {
          stdout.write('Enter the Podman image name to use: ');
          image = stdin.readLineSync();
          if (image == null || image.trim().isEmpty) {
            stderr.writeln('Error: No image name provided.');
            exit(1);
          }
        }

        final currentDir = Directory.current.path;

        final process = await Process.start('podman', [
          'run',
          '--rm',
          '--name',
          image,
          '-p',
          '10000:10000',
          '--volume',
          '$currentDir:/app:Z',
          image,
        ], mode: ProcessStartMode.inheritStdio);
        await process.exitCode;
      } else if (subcommand == 'ps') {
        final result = await Process.run('podman', ['ps']);
        stdout.write(result.stdout);
        stderr.write(result.stderr);
        exit(result.exitCode);
      } else if (subcommand == 'exec') {
        // Collect flags and container ID
        final execArgs = args.sublist(1);
        List<String> flags = [];
        String? containerId;

        for (final arg in execArgs) {
          if (arg == '-i' || arg == '-t' || arg == '-it' || arg == '-ti') {
            flags.addAll(arg.split(''));
          } else if (!arg.startsWith('-')) {
            containerId = arg;
            break;
          }
        }

        if (containerId == null || containerId.trim().isEmpty) {
          stdout.write('Enter the container ID to exec into: ');
          containerId = stdin.readLineSync();
          if (containerId == null || containerId.trim().isEmpty) {
            stderr.writeln('Error: No container ID provided.');
            exit(1);
          }
        }

        // Ensure '-i' and '-t' flags are included
        if (!flags.contains('i')) flags.add('i');
        if (!flags.contains('t')) flags.add('t');

        // Sort flags to '-it' order
        flags.sort();

        final flagString = '-${flags.join('')}';

        final process = await Process.start('podman', [
          'exec',
          flagString,
          containerId,
          '/bin/bash',
        ], mode: ProcessStartMode.inheritStdio);
        final exitCode = await process.exitCode;
        exit(exitCode);
      } else if (subcommand == 'clean') {
        final steps = [
          ['podman', 'machine', 'stop'],
          ['podman', 'machine', 'rm', '-f', 'podman-machine-default'],
        ];

        for (final step in steps) {
          stdout.writeln('Running command: \u001b[36m${step.join(' ')}\u001b[0m');
          final result = await Process.run(step[0], step.sublist(1));
          stdout.write(result.stdout);
          stderr.write(result.stderr);
        }

        // Remove stale Podman temp and state directories (macOS)
        final cleanupCommands = [
          ['sudo', 'rm', '-rf', '/var/folders'],
          ['rm', '-rf', '${Platform.environment['HOME']}/.local/share/containers'],
        ];
        for (final cmd in cleanupCommands) {
          stdout.writeln('Running command: \u001b[36m${cmd.join(' ')}\u001b[0m');
          final result = await Process.run(cmd[0], cmd.sublist(1));
          stdout.write(result.stdout);
          stderr.write(result.stderr);
          if (cmd.join(' ').contains('.local/share/containers')) {
            if (result.exitCode == 0) {
              stdout.writeln('Successfully removed ${Platform.environment['HOME']}/.local/share/containers');
            } else {
              stderr.writeln('Failed to remove ${Platform.environment['HOME']}/.local/share/containers (exit code: [31m${result.exitCode}\u001b[0m)');
            }
          }
        }
        exit(0);
      } else if (subcommand == 'run') {
        // 'run' subcommand: prompt for image and port, run container without build or removal
        String? image = argResults?['image'];

        if (image == null || image.trim().isEmpty) {
          stdout.write('Enter the Podman image name to use: ');
          image = stdin.readLineSync();
          if (image == null || image.trim().isEmpty) {
            stderr.writeln('Error: No image name provided.');
            exit(1);
          }
        }

        final containerName = image.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');

        stdout.write('Enter host port to bind (e.g. 10000): ');
        final port = stdin.readLineSync();
        if (port == null || port.trim().isEmpty) {
          stderr.writeln('Error: Port is required.');
          exit(1);
        }

        final process = await Process.start('podman', [
          'run',
          '-d',
          '--name',
          containerName,
          '--restart=always',
          '-p',
          '127.0.0.1:$port:$port',
          image,
        ]);
        stdout.addStream(process.stdout);
        stderr.addStream(process.stderr);
        final exitCode = await process.exitCode;
        exit(exitCode);
      }
    }

    final showLogs = argResults?['logs'] == true;

    if (showLogs) {
      // Detect the last built image
      final result = await Process.run('podman', [
        'images',
        '--format',
        '{{.Repository}} {{.CreatedAt}}',
      ]);
      if (result.exitCode != 0) {
        stderr.writeln('Error listing images: ${result.stderr}');
        exit(1);
      }

      final lines = (result.stdout as String).trim().split('\n');
      if (lines.isEmpty) {
        stderr.writeln('No Podman images found.');
        exit(1);
      }

      // Sort by creation date, assume newest first
      lines.sort((a, b) {
        final dateA =
            DateTime.tryParse(a.split(' ').sublist(1).join(' ')) ??
            DateTime(1970);
        final dateB =
            DateTime.tryParse(b.split(' ').sublist(1).join(' ')) ??
            DateTime(1970);
        return dateB.compareTo(dateA);
      });

      final lastImage = lines.first.split(' ').first;

      // Get container ID for the last image
      final psResult = await Process.run('podman', [
        'ps',
        '-a',
        '--filter',
        'ancestor=$lastImage',
        '--format',
        '{{.ID}}',
      ]);
      if (psResult.exitCode != 0 ||
          (psResult.stdout as String).trim().isEmpty) {
        stderr.writeln('No container found for image $lastImage.');
        exit(1);
      }

      final containerId = (psResult.stdout as String).trim().split('\n').first;

      // Show logs
      final logProcess = await Process.start('podman', [
        'logs',
        '-f',
        containerId,
      ]);
      stdout.addStream(logProcess.stdout);
      stderr.addStream(logProcess.stderr);
      await logProcess.exitCode;
      return;
    }

    // Default 'learmond podman' command:
    // 1. Prompt for image name if not provided
    String? image = argResults?['image'];
    if (image == null || image.trim().isEmpty) {
      stdout.write('Enter the Podman image name to use: ');
      image = stdin.readLineSync();
      if (image == null || image.trim().isEmpty) {
        stderr.writeln('Error: No image name provided.');
        exit(1);
      }
    }

    // 2. Ensure Podman VM is running
    await ensurePodmanRunning();

    // 3. Remove all existing containers
    final psResult = await Process.run('podman', ['ps', '-aq']);
    if (psResult.exitCode != 0) {
      stderr.write(psResult.stderr);
      exit(psResult.exitCode);
    }
    final containerIds = (psResult.stdout as String)
        .trim()
        .split('\n')
        .where((id) => id.trim().isNotEmpty)
        .toList();
    if (containerIds.isNotEmpty) {
      // Stop all containers
      final stopProcess = await Process.start('podman', ['stop', ...containerIds]);
      await stopProcess.stdout.pipe(stdout);
      await stopProcess.stderr.pipe(stderr);
      final stopExit = await stopProcess.exitCode;
      if (stopExit != 0) {
        stderr.writeln('Error: podman stop failed with exit code $stopExit.');
        exit(stopExit);
      }
      // Remove all containers
      final rmProcess = await Process.start('podman', ['rm', '-f', ...containerIds]);
      await rmProcess.stdout.pipe(stdout);
      await rmProcess.stderr.pipe(stderr);
      final rmExit = await rmProcess.exitCode;
      if (rmExit != 0) {
        stderr.writeln('Error: podman rm failed with exit code $rmExit.');
        exit(rmExit);
      }
    }

    // 4. Remove the existing image if it exists
    final imagesResult = await Process.run('podman', ['images', '-q', image]);
    if (imagesResult.exitCode == 0) {
      final imageIds = (imagesResult.stdout as String)
          .trim()
          .split('\n')
          .where((id) => id.trim().isNotEmpty)
          .toList();
      if (imageIds.isNotEmpty) {
        final rmiProcess = await Process.start('podman', ['rmi', '-f', image]);
        await rmiProcess.stdout.pipe(stdout);
        await rmiProcess.stderr.pipe(stderr);
        final rmiExit = await rmiProcess.exitCode;
        if (rmiExit != 0) {
          stderr.writeln('Error: podman rmi failed with exit code $rmiExit.');
          exit(rmiExit);
        }
      }
    }

    // 5. Build the new image
    final buildProcess = await Process.start('podman', ['build', '-t', image, '.']);
    await buildProcess.stdout.pipe(stdout);
    await buildProcess.stderr.pipe(stderr);
    final buildExit = await buildProcess.exitCode;
    if (buildExit != 0) {
      stderr.writeln('Error: podman build failed with exit code $buildExit.');
      exit(buildExit);
    }
    // 6. Do not run the container and do not prompt for any ports.
  }
}