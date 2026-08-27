import 'dart:io';

import 'package:args/command_runner.dart';

import '../lib/src/kelicap_command_runner.dart';
import '../lib/src/util/logger.dart';

Future<void> main(List<String> args) async {
  final runner = KelicapCommandRunner();

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    error('$e');
    exit(64);
  } catch (e) {
    error('$e');
    exit(1);
  }
}
