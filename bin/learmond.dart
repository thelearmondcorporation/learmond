import 'package:args/command_runner.dart';
import 'package:learmond/core/context.dart';
import 'package:learmond/domains/repo/repo_command.dart';

void main(List<String> args) {
  final context = Context.defaultContext();

  final runner = CommandRunner(
    'learmond',
    'Learmond unified CLI',
  )..addCommand(RepoCommand(context));

  runner.run(args);
}