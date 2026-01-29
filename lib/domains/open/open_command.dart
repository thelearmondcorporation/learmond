import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

/// Command to open a file in nano editor.
class OpenCommand extends Command {
  @override
  final name = 'open';

  @override
  final description = 'Open a file in the nano editor.';

  OpenCommand() {
  }

  @override
  Future<void> run() async {
    if (argResults == null || argResults!.rest.isEmpty) {
      stderr.writeln('Error: No file specified.');
      printUsage();
      return;
    }
    final openfile = argResults!.rest[0];
    try {
      final process = await Process.start(
        'nano',
        [openfile],
        mode: ProcessStartMode.inheritStdio,
      );
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        stderr.writeln('nano exited with code $exitCode while opening "$openfile".');
      }
    } catch (e) {
      stderr.writeln('Failed to open file "$openfile" with nano: $e');
    }
  }
}