# Kelicap CLI

[![Kelicap Web Framework](../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_cli?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/master/LICENSE)

A command-line tool for creating and managing Kelicap projects.

## Usage

`kelicap_cli` is not meant to be used as a dependency but a command-line tool. Hence, you have to "activate" it:

```bash
dart pub global activate kelicap_cli
```

Dart will detect automatically if you have added the Pub executables path to your environment variables. Follow its instructions if you haven't.

To create a new Kelicap project (note that the actual command is `kelicap`, not `kelicap_cli`):

```bash
kelicap create <package_name>
```

To remove the `build/` and `.dart_tool/` directory (similar to `flutter clean`), run in your project directory:

```bash
kelicap clean
```

## Future Plans

* [ ] Run `dart pub get` (or prompt the user to run) after creating a project.
* [ ] Add `kelicap build` and `kelicap serve` command
* [ ] Generate skeleton code for custom component
