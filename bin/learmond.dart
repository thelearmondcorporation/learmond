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

import 'package:learmond/domains/podman/podman_command.dart';

void main(List<String> args) async {
  final context = Context.defaultContext();

  final runner = CommandRunner('learmond', 'Learmond unified CLI');

  // Add commands safely
  try {
    runner
      ..addCommand(RepoCommand(context))
      ..addCommand(DoctorCommand())
      ..addCommand(SelfInstallCommand())
      ..addCommand(FlutterBuildCommand())
      ..addCommand(FlutterCommand())
      ..addCommand(CleanCommand())
      ..addCommand(CreateCommand())
      ..addCommand(FormatCommand())
      ..addCommand(TestCommand())
      ..addCommand(AnalyzeCommand())
      ..addCommand(ChangelogCommand())
      ..addCommand(GithubPushCommand())
      ..addCommand(LicenseCliCommand())
      ..addCommand(PublishCommand())
      ..addCommand(RunCommand())
      ..addCommand(FixCommand())
      //PODMAN COMMANDS
      ..addCommand(PodmanCommand());
  } catch (e, st) {
    print('Failed to initialize CLI commands: $e');
    print('Did you add the new imports for the command in bin/learmond.dart?');
    print(st);
    exit(1);
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
