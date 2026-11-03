# Kelicap Common

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_common?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

Definitions shared by the Kelicap runtime, [`kelicap`](https://pub.dev/packages/kelicap), and its compiler, [`kelicap_compiler`](https://pub.dev/packages/kelicap_compiler), so that both read the same values:

* `ViewEncapsulation`, how a component's styles are scoped
* `ChangeDetectionStrategy` and the states of change detection
* `Visibility`, which directives other directives can inject
* `isDevMode`, whether the app runs with assertions enabled, as in a development build

Applications don't depend on this package: `package:kelicap/kelicap.dart` exports what they need of it.
