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
  return weservProxiedUrl(url, width: width, height: height);
}

/// Platform-independent core of [proxiedImageUrl] (split out so it is testable
/// off-web).
///
/// Already-proxied detection compares the parsed host, never a string prefix:
/// `https://images.weserv.nl.attacker.example/x` and
/// `https://images.weserv.nl@attacker.example/x` must still be treated as
/// untrusted hosts and routed through the proxy.
String weservProxiedUrl(String url, {int? width, int? height}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  final uri = Uri.tryParse(trimmed);
  final host = uri?.host ?? '';
  if (uri?.scheme == 'https' && host == 'images.weserv.nl') return trimmed;
  // Firebase Storage URLs carry access tokens; never send them to a third party.
  if (host == 'firebasestorage.googleapis.com' ||
      host.endsWith('.googleusercontent.com')) {
    return trimmed;
  }

  // weserv expects the full source URL (including https://) in `url`.
  final params = <String, String>{
    'url': trimmed,
    if (width != null) 'w': '$width',
    if (height != null) 'h': '$height',
    if (width != null || height != null) 'fit': 'cover',
  };
  return Uri.https('images.weserv.nl', '/', params).toString();
}
