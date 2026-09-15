import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/auth/loopback_redirect_server.dart';

void main() {
  test('captures the IdP redirect on the loopback port and answers HTML',
      () async {
    final port = 30000 + DateTime.now().millisecond % 20000;
    final pinned = await LoopbackRedirectServer.bind(
      Uri.parse('http://127.0.0.1:$port/auth/callback'),
    );
    final waiting = pinned.wait(timeout: const Duration(seconds: 5));

    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse(
        'http://127.0.0.1:$port/auth/callback?code=CODE-1&state=STATE-1',
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final redirect = await waiting;

    expect(redirect.queryParameters['code'], 'CODE-1');
    expect(redirect.queryParameters['state'], 'STATE-1');
    expect(body, contains('登录完成'));
    client.close();
    await pinned.close();
  });

  test('skips non-redirect paths (favicon noise) until the real one',
      () async {
    final port = 30000 + DateTime.now().millisecond % 20000 + 1;
    final pinned = await LoopbackRedirectServer.bind(
      Uri.parse('http://127.0.0.1:$port/auth/callback'),
    );
    final waiting = pinned.wait(timeout: const Duration(seconds: 5));

    final client = HttpClient();
    final noise = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/favicon.ico'),
    );
    final noiseResponse = await noise.close();
    expect(noiseResponse.statusCode, HttpStatus.notFound);

    final real = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/auth/callback?code=C2&state=S2'),
    );
    await real.close();
    final redirect = await waiting;

    expect(redirect.queryParameters['code'], 'C2');
    client.close();
    await pinned.close();
  });
}
