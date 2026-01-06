import 'package:args/command_runner.dart';
import 'build_command.dart';

class FlutterCommand extends Command {
  @override
  final name = 'flutter';
  @override
  final description = 'Flutter related commands';

  FlutterCommand() {
    addSubcommand(FlutterBuildCommand());
  }

  @override
  Future<void> run() async {
    print('Use "learmond flutter build <apk|appbundle>"');
  }
}
