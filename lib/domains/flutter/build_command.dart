import 'package:args/command_runner.dart';
import 'build_apk_command.dart';
import 'build_appbundle_command.dart';

class FlutterBuildCommand extends Command {
  @override
  final name = 'build';
  @override
  final description = 'Build Flutter APK or AppBundle';

  FlutterBuildCommand() {
    addSubcommand(FlutterBuildApkCommand());
    addSubcommand(FlutterBuildAppBundleCommand());
  }

  @override
  Future<void> run() async {
    print('Use "learmond flutter build <apk|appbundle>"');
  }
}
