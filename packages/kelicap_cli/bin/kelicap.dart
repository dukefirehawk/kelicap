import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:kelicap_cli/src/kelicap_command_runner.dart';
import 'package:kelicap_cli/src/util/logger.dart';

Future<void> main(List<String> args) async {
  final runner = KelicapCommandRunner();

  try {
    exitCode = await runner.run(args) ?? 0;
  } on UsageException catch (e) {
    error('$e');
    exit(64);
  } catch (e) {
    error('$e');
    exit(1);
  }
}
