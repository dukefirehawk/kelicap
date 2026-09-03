# Installation

This guide will help you set up your environment, install the Kelicap tooling, create your first project, and run a development server.

## Prerequisites

Before building applications with Kelicap, ensure your environment meets the following requirements:

- **Dart SDK**: `3.13.0` or later (`dart --version`).
- **Web Browser**: Any modern browser (Chrome, Firefox, Edge, Safari) supporting modern JavaScript standards and ES modules.
- **Operating System**: Linux, macOS, or Windows.

## Installing the Kelicap CLI (`kelicap_cli`)

Kelicap provides a command-line interface tool to simplify project scaffolding and component generation.

### Global Activation

Ensure your global Dart `bin` path is added to your system's `PATH` environment variable:

- **Linux/macOS**: `~/.pub-cache/bin`
- **Windows**: `%LOCALAPPDATA%\Pub\Cache\bin`

Activate `kelicap_cli` globally using the Dart package manager:

```bash
dart pub global activate kelicap_cli
```

Verify installation:

```bash
kelicap --version
```
