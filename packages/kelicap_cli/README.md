# Kelicap CLI

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_cli?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

A command-line tool to create Kelicap projects. Its command is `kelicap`.

## Installation

`kelicap_cli` is a tool, not a dependency of your project. Activate it globally:

```bash
dart pub global activate kelicap_cli
```

If `kelicap` is not found afterwards, add Pub's executables directory to your `PATH`, as `dart pub global activate` explains.

## Usage

Create a project, a to-do list app with a component, a service and styles, and get its packages:

```bash
kelicap create my_app
cd my_app
dart run build_runner serve web:8080
```

| Option | What it does |
| --- | --- |
| `--path`, `-p` | The directory to create the project in (default: the current one) |
| `--force`, `-f` | Create it in a directory that is not empty, overwriting files |
| `--no-pub` | Don't run `dart pub get` after creating it |

Delete a project's `build/` and `.dart_tool/` directories, as `flutter clean` does:

```bash
kelicap clean
```

`kelicap --version` prints the version, and `kelicap help <command>` the options of a command.

## Future plans

* [ ] `kelicap build` and `kelicap serve` commands
* [ ] Generating the skeleton of a component
