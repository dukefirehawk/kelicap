import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:kelicap_cli/src/commands/create.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late List<String> pubGetDirectories;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('kelicap_cli_test');
    pubGetDirectories = [];
  });

  tearDown(() => root.delete(recursive: true));

  Future<int?> create(List<String> args, {int pubGetExitCode = 0}) {
    final runner = CommandRunner<int>('kelicap', 'test')
      ..addCommand(
        CreateCommand(
          runPubGet: (workingDirectory) async {
            pubGetDirectories.add(workingDirectory);
            return ProcessResult(0, pubGetExitCode, '', 'pub get failed');
          },
        ),
      );
    return runner.run(['create', ...args]);
  }

  test('runs pub get in the project created at --path', () async {
    final exitCode = await create(['foo', '--path', root.path]);

    final expected = p.normalize(p.join(root.path, 'foo'));
    expect(exitCode, 0);
    expect(pubGetDirectories, [expected]);
    expect(File(p.join(expected, 'pubspec.yaml')).existsSync(), isTrue);
  });

  test('returns the exit code of a failed pub get', () async {
    final exitCode = await create([
      'foo',
      '--path',
      root.path,
    ], pubGetExitCode: 65);

    expect(exitCode, 65);
  });

  test('does not run pub get with --no-pub', () async {
    final exitCode = await create(['foo', '--path', root.path, '--no-pub']);

    expect(exitCode, 0);
    expect(pubGetDirectories, isEmpty);
  });
}
