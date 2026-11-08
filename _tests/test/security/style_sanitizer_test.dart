@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:kelicap/src/security/style_sanitizer.dart';

void main() {
  group('Style sanitizer', () {
    test('sanitizes values', () {
      expect(internalSanitizeStyle('abc'), 'abc');
      expect(internalSanitizeStyle('50px'), '50px');
      expect(internalSanitizeStyle('rgb(255, 0, 0)'), 'rgb(255, 0, 0)');
    });
    test('sanitizes style binding', () {
      expect(internalSanitizeStyle('width: 10px'), 'width: 10px');
      expect(internalSanitizeStyle('z-index: 1001'), 'z-index: 1001');
      expect(internalSanitizeStyle('z-index : 1001'), 'z-index : 1001');
      expect(internalSanitizeStyle('z-index: expression(haha)'), 'unsafe');
      expect(internalSanitizeStyle('z-index : expression(haha)'), 'unsafe');
      expect(
        internalSanitizeStyle('transform: translateX(10px);width: 10px'),
        'transform: translateX(10px);width: 10px',
      );
      expect(
        internalSanitizeStyle(
          'transform: translateX(10px);width: expression(haha)',
        ),
        'unsafe',
      );
      String bindingValue = 'z-index: 1002;left: -1000px;width: 1000px;';
      expect(internalSanitizeStyle(bindingValue), bindingValue);
    });
    test('rejects unbalanced quotes', () {
      expect(internalSanitizeStyle('"value" "'), 'unsafe');
    });
    test('sanitizes functions', () {
      expect(internalSanitizeStyle('expression(haha)'), 'unsafe');
    });
    test('accepts transform functions', () {
      expect(internalSanitizeStyle('rotate(90deg)'), 'rotate(90deg)');
      expect(internalSanitizeStyle('rotate(javascript:evil())'), 'unsafe');
      expect(
        internalSanitizeStyle('translateX(12px, -5px)'),
        'translateX(12px, -5px)',
      );
      expect(
        internalSanitizeStyle('translateX(12px) scaleX(1.5)'),
        'translateX(12px) scaleX(1.5)',
      );
      expect(internalSanitizeStyle('scale3d(1, 1, 2)'), 'scale3d(1, 1, 2)');
    });
    test('accepts url in any case', () {
      for (final value in [
        'URL(https://cdn.example.com/a.png)',
        'Url(https://cdn.example.com/a.png)',
      ]) {
        expect(internalSanitizeStyle(value), value);
      }
      expect(internalSanitizeStyle('URL(javascript:evil())'), 'unsafe');
    });
    test('accepts url among declarations, with spaces and semicolons', () {
      for (final value in [
        'url(https://cdn.example.com/a.png);',
        'width: 10px; url(https://cdn.example.com/a.png)',
        'width: 10px; url(https://cdn.example.com/a.png); ',
      ]) {
        expect(internalSanitizeStyle(value), value.trim());
      }
      expect(
        internalSanitizeStyle('width: 10px; url(javascript:evil());'),
        'unsafe',
      );
    });
    test('sanitizes urls', () {
      expect(internalSanitizeStyle('url(foo/bar.png)'), 'url(foo/bar.png)');
      expect(internalSanitizeStyle('url(javascript:evil())'), 'unsafe');
      expect(internalSanitizeStyle('url(strangeprotocol:evil)'), 'unsafe');
    });
    test('accepts urls with a safe scheme', () {
      for (final value in [
        'url(https://cdn.example.com/a.png)',
        'url(http://cdn.example.com/a.png)',
        'url("https://cdn.example.com/a.png")',
        "url('https://cdn.example.com/a.png')",
        'url( https://cdn.example.com/a.png )',
        'url("foo/bar.png")',
        'url(data:image/png;base64,iVBORw0KGgo=)',
        'url("data:image/png;base64,iVBORw0KGgo=")',
        'url(https://cdn.example.com/a.png);width: 10px',
      ]) {
        expect(internalSanitizeStyle(value), value);
      }
    });
    test('rejects urls with an unsafe scheme', () {
      for (final value in [
        'url(javascript:evil)',
        'url("javascript:evil")',
        "url('javascript:evil')",
        'url( javascript:evil )',
        'url(" javascript:evil")',
        'url(JAVASCRIPT:evil)',
        'url(data:text/html;base64,PHNjcmlwdD4=)',
        'url(javascript:evil);width: 10px',
        'width: 10px;url("javascript:evil")',
      ]) {
        expect(internalSanitizeStyle(value), 'unsafe', reason: value);
      }
    });
    test('rejects urls that could break out of a string or hide a scheme', () {
      for (final value in [
        r'url(javascript\3a evil)',
        r'url("javascript\3a evil")',
        'url("foo.png)',
        'url(foo.png")',
        '''url("foo.png')''',
        'url("foo"bar".png")',
      ]) {
        expect(internalSanitizeStyle(value), 'unsafe', reason: value);
      }
    });
  });
}
