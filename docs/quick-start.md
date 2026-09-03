# Quick Start

This guide will help you set up create your first project, and run a development server.

## Creating a New Project

### Using `kelicap_cli`

To initialize a new Kelicap web application, run:

```bash
kelicap create my_kelicap_app
cd my_kelicap_app
```

### Project Structure Walkthrough

A standard Kelicap application follows this directory layout:

```text
my_kelicap_app/
├── lib/
│   ├── app_component.dart        # Root component logic
│   ├── app_component.html        # Root template HTML
│   └── app_component.css         # Component-scoped styles
├── web/
│   ├── index.html                # Entry HTML page
│   └── main.dart                 # Application entry point & bootstrapping
├── pubspec.yaml                  # Project dependencies & Dart configuration
└── build.yaml                    # Builder options for kelicap_compiler & web compilers
```

### Manual Dependency Setup (`pubspec.yaml`)

If configuring an existing Dart package for Kelicap, add the following to `pubspec.yaml`:

```yaml
name: my_kelicap_app
description: A native web app built with Kelicap.
environment:
  sdk: '>=3.13.0 <4.0.0'

dependencies:
  kelicap: ^1.0.0
  kelicap_router: ^1.0.0
  kelicap_forms: ^1.0.0
  web: ^1.1.1

dev_dependencies:
  build_runner: ^2.4.0
  build_web_compilers: ^4.6.0
  lints: ^6.1.0
```

Install dependencies:

```bash
dart pub get
```

## Running & Building Applications

### Development Server

Run the local development server with hot-reload / automatic re-compilation using `build_runner`:

```bash
dart run build_runner serve
```

By default, the application serves at `http://localhost:8080`.

### Production Build

To compile your application for production deployment (generating optimized JavaScript, CSS, and HTML assets in the `build/` directory):

```bash
dart run build_runner build --release -o build
```

The output in `build/web/` is ready to be served by any web server (e.g., Nginx, Apache, Firebase Hosting, Vercel)
