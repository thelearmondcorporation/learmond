import 'dart:io';
import 'package:logger/logger.dart';
import 'package:core/core.dart';
import 'args_parser.dart';

class GrepCommand {
  final Logger logger = Logger();

  Future<void> execute(List<String> arguments) async {
    final argsParser = GrepArgsParser();
    final args = argsParser.parse(arguments);

    if (args == null) {
      logger.e('Invalid arguments provided.');
      return;
    }

    final directory = Directory(args.directoryPath);
    if (!directory.existsSync()) {
      logger.e('Directory does not exist: ${args.directoryPath}');
      return;
    }

    final regex = RegExp(args.pattern);
    final files = directory
        .listSync(recursive: args.recursive)
        .whereType<File>()
        .where((file) => file.path.endsWith(args.fileExtension));

    for (final file in files) {
      final lines = await file.readAsLines();
      for (var i = 0; i < lines.length; i++) {
        if (regex.hasMatch(lines[i])) {
          logger.i(
              'Match found in ${file.path} at line ${i + 1}: ${lines[i]}');
        }
      }
    }
  }
}