import 'package:flutter/foundation.dart' show kIsWeb;

/// On Flutter Web, remote image hosts that don't send
/// `Access-Control-Allow-Origin` fail with `statusCode: 0` when we try to fetch
/// them via `CachedNetworkImage` / `Image.network`. Wrap those URLs through a
/// CORS-friendly image proxy so the browser can decode the bytes.
///
/// - Uses [images.weserv.nl](https://images.weserv.nl) which always sends
///   `Access-Control-Allow-Origin: *`.
/// - No-op on non-web platforms and for empty/invalid URLs.
/// - Passes through the URL if it already points at the proxy (idempotent).
String proxiedImageUrl(String url, {int? width, int? height}) {
  if (!kIsWeb) return url;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('https://images.weserv.nl')) return trimmed;

  final withoutScheme = trimmed.replaceFirst(RegExp(r'^https?://'), '');
  final params = <String, String>{
    'url': withoutScheme,
    if (width != null) 'w': '$width',
    if (height != null) 'h': '$height',
    if (width != null || height != null) 'fit': 'cover',
  };
  return Uri.https('images.weserv.nl', '/', params).toString();
}
