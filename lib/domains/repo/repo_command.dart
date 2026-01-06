import 'package:args/command_runner.dart';
import 'package:learmond/core/context.dart';
import 'repo_init_command.dart';

class RepoCommand extends Command {
  final Context context;

  @override
  final name = 'repo';

  @override
  final description = 'Repository management commands';

  RepoCommand(this.context) {
    addSubcommand(RepoInitCommand(context));
  }
}