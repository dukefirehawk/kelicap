/// [SanitizationService] is used by the views to sanitize values as create
/// SafeValue equivalents that can be used to bind to in templates.
abstract class SanitizationService {
  // Sanitizes html content.
  String? sanitizeHtml(dynamic value);
  // Sanitizes css style.
  String? sanitizeStyle(dynamic value);
  // Sanitizes url link.
  String? sanitizeUrl(dynamic value);
  // Sanitizes resource loading url.
  String? sanitizeResourceUrl(dynamic value);
}
