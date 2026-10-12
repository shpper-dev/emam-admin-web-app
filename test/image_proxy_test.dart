import 'package:emam_admin_web_app/core/utils/image_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weservProxiedUrl', () {
    test('leaves genuine weserv URLs untouched', () {
      const url =
          'https://images.weserv.nl/?url=https%3A%2F%2Fa.example%2Fp.png';
      expect(weservProxiedUrl(url), url);
    });

    test('proxies lookalike hosts instead of treating them as proxied', () {
      for (final url in [
        'https://images.weserv.nl.attacker.example/p.png',
        'https://images.weserv.nl@attacker.example/p.png',
        'http://images.weserv.nl/p.png',
      ]) {
        final result = Uri.parse(weservProxiedUrl(url));
        expect(result.host, 'images.weserv.nl', reason: url);
        expect(result.queryParameters['url'], url, reason: url);
      }
    });

    test('does not send Firebase Storage or googleusercontent URLs out', () {
      const a = 'https://firebasestorage.googleapis.com/v0/b/x/o/p.png?token=t';
      const b = 'https://lh3.googleusercontent.com/a/photo';
      expect(weservProxiedUrl(a), a);
      expect(weservProxiedUrl(b), b);
    });

    test('proxies ordinary hosts with size params', () {
      final result = Uri.parse(
        weservProxiedUrl('https://cdn.example/p.png', width: 112, height: 112),
      );
      expect(result.host, 'images.weserv.nl');
      expect(result.queryParameters['url'], 'https://cdn.example/p.png');
      expect(result.queryParameters['w'], '112');
    });

    test('empty input stays empty', () {
      expect(weservProxiedUrl('   '), '');
    });
  });
}
