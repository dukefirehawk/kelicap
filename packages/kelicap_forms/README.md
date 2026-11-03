# Kelicap Forms

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_forms?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

Forms for Kelicap, in two styles:

* **Template-driven:** bind inputs to your component's fields with `[(ngModel)]`, for simple forms.
* **Reactive:** build the form's model in Dart, with `ControlGroup`s and `Control`s, and bind it with `[ngFormModel]` and `ngControl`, for complex or dynamic ones.

Both track each control's value, validity and state (`pristine`, `dirty`, `touched`), and validate with the built-in validators (`required`, `minlength`, `maxlength`, `pattern`) or your own. They work with text, number, checkbox, radio and select inputs.

## Installation

```yaml
dependencies:
  kelicap: ^1.1.2
  kelicap_forms: ^1.1.2
```

## Template-driven forms

```dart
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_forms/kelicap_forms.dart';

@Component(
  selector: 'greeting-form',
  directives: [coreDirectives, formDirectives],
  template: '''
    <input [(ngModel)]="name" required #nameModel="ngForm">
    <p *ngIf="!nameModel.valid">A name is required</p>
    <p>Hello {{name}}</p>
  ''',
)
class GreetingFormComponent {
  String name = 'Kelicap';
}
```

## Reactive forms

```dart
@Component(
  selector: 'login-form',
  directives: [formDirectives],
  template: '''
    <form [ngFormModel]="form" (ngSubmit)="login()">
      <input ngControl="user" required>
      <input ngControl="password" type="password" required>
      <button type="submit" [disabled]="!form.valid">Log in</button>
    </form>
  ''',
)
class LoginFormComponent {
  final form = ControlGroup({
    'user': Control(''),
    'password': Control(''),
  });

  void login() => print(form.value);
}
```

## Custom inputs

To use a component of your own as a form control, implement `ControlValueAccessor` and provide it as `ngValueAccessor`. When it reads a DOM event, take a typed `Event` in its `@HostListener` (`@HostListener('input', [r'$event'])`), rather than reading `$event.target.value`, which fails in release builds compiled with dart2js.
