import 'dart:js_interop';

import 'package:kelicap/src/meta.dart';
import 'package:web/web.dart' show Element;

import 'dom_sanitization_service.dart' show SafeHtml;

/// Sets [Element.innerHTML] _without_ sanitizing the HTML output.
///
/// Requires use of a [SafeHtml] wrapper created by [DomSanitizationService]:
///     var safeHtml = domSanitizationService.bypassSecurityTrustHtml('...');
///
/// (This allows security reviews to easily search for and catch exceptions)
///
/// _All_ elements are allowed, including `<script>` tags or other elements
/// that could cause cross-site scripting, unsafe URLs, and more. Only
/// **trusted** data sources should be used when using `[safeInnerHtml]`.
///
/// __Example use__:
///
/// ```dart
/// @Component(
///   selector: 'my-component',
///   directives: const [SafeInnerHtmlDirective],
///   template: '''
///     <div [safeInnerHtml]="trustedHtml"></div>
///   ''',
/// )
/// class MyComponent {
///   /// WARNING: This will be embedded directly into the HTML.
///   final SafeHtml trustedHtml;
///
///   MyComponent(DomSanitizationService domSanitizationService)
///       : trustedHtml = domSanitizationService.bypassSecurityTrustHtml(
///             'I solemnly swear that this <script></script> is OK!');
/// }
/// ```
@Directive(selector: '[safeInnerHtml]')
class SafeInnerHtmlDirective {
  final Element? _element;

  SafeInnerHtmlDirective(@Optional() this._element);

  @Input()
  set safeInnerHtml(dynamic safeInnerHtml) {
    // print('Setting inner html as $safeInnerHtml');
    if (safeInnerHtml is SafeHtml) {
      // `setHTMLUnsafe` parses without sanitizing, which is what this directive
      // is for and what the `NodeTreeSanitizer.trusted` argument meant when
      // this used `setInnerHtml`. Assigning `textContent` instead would insert
      // the markup as a text node, rendering the tags as visible characters.
      _element?.setHTMLUnsafe(
        safeInnerHtml.changingThisWillBypassSecurityTrust.toJS,
      );
    } else if (safeInnerHtml == null) {
      _element?.textContent = '';
    } else {
      // A regular string is not allowed since a security audit needs to be able
      // to search for SafeHtml and identify all locations where we are
      // bypassing sanitization. This also enforces SafeHtml usage at the
      // origin instead of passing a primitive string through layers
      // of code which could introduce mutations making security auditing
      // hard.
      throw UnsupportedError('SafeHtml required (got $safeInnerHtml)');
    }
  }
}
