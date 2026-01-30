import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:learmond/core/context.dart';
import 'package:learmond/domains/repo/repo_command.dart';
import 'package:learmond/domains/doctor/doctor_command.dart';
import 'package:learmond/domains/self_install_command.dart';
import 'package:learmond/domains/flutter/flutter_command.dart';
import 'package:learmond/domains/flutter/build_command.dart';
import 'package:learmond/domains/clean/clean_command.dart';
import 'package:learmond/domains/create/create_command.dart';
import 'package:learmond/domains/format/format_command.dart';
import 'package:learmond/domains/test/test_command.dart';
import 'package:learmond/domains/analyze/analyze_command.dart';
import 'package:learmond/domains/changelog/changelog_command.dart';
import 'package:learmond/domains/push/github_push_command.dart';
import 'package:learmond/domains/publish/publish_command.dart';
import 'package:learmond/domains/run/run_command.dart';
import 'package:learmond/domains/license/license_cli_command.dart';
import 'package:learmond/domains/fix/fix_command.dart';

//MACHINE COMMANDS IMPORT
import 'package:learmond/domains/find/find_command.dart';
import 'package:learmond/domains/open/open_command.dart';
import 'package:learmond/domains/storage/storage_command.dart';
import 'package:learmond/domains/grep/grep_command.dart';
import 'package:learmond/domains/list/list_command.dart';

// NGINX COMMAND IMPORT
import 'package:learmond/domains/nginx/nginx_command.dart';

// PODMAN COMMAND IMPORT
import 'package:learmond/domains/podman/podman_command.dart';

// APP CLI COMMANDS
import 'package:learmond/domains/app_cli/return_command.dart';

void main(List<String> args) async {
  final context = Context.defaultContext();

  final runner = CommandRunner('learmond', 'Learmond unified CLI');

  // Add commands safely (skip duplicates)
  final cmdList = <Command>[
    RepoCommand(context),
    DoctorCommand(),
    SelfInstallCommand(),
    SelfReinstallCommand(),
    FlutterBuildCommand(),
    FlutterCommand(),
    CleanCommand(),
    CreateCommand(),
    FormatCommand(),
    TestCommand(),
    AnalyzeCommand(),
    ChangelogCommand(),
    GithubPushCommand(),
    LicenseCliCommand(),
    PublishCommand(),
    RunCommand(),
    FixCommand(),
    PodmanCommand(),
    FindCommand(),
    OpenCommand(),
    NginxCommand(),
    StorageCommand(),
    PrintLargestFilesCommand(),
    ReturnCommand(),
    GrepCommand(),
    ListCommand(),
  ];

  for (final cmd in cmdList) {
    final name = cmd.name;
    if (runner.commands.containsKey(name)) {
      stderr.writeln('Skipping duplicate command: $name');
      continue;
    }
    try {
      runner.addCommand(cmd);
    } catch (e, st) {
      stderr.writeln('Failed to add command $name: $e');
      stderr.writeln(st);
    }
  }

  // Run the command and handle runtime errors
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    print(e.message);
    print(e.usage);
    exit(64);
  } catch (e, st) {
    print('Unexpected error: $e');
    print(st);
    exit(1);
  }
}
