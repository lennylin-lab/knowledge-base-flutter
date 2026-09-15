import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/auth/auth_controller.dart';
import 'package:knowledge_base_flutter/core/network/agent_stream_client.dart';
import 'package:knowledge_base_flutter/core/network/chat_transport.dart';
import 'package:knowledge_base_flutter/core/network/sse_client.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';

/// Records the headers each [open] received and yields an empty stream.
class _RecordingTransport implements ChatTransport {
  final List<Map<String, String>?> opens = [];

  @override
  Future<Stream<Uint8List>> open(
    Uri uri,
    String? jsonBody, {
    Map<String, String>? headers,
  }) async {
    opens.add(headers);
    return const Stream<Uint8List>.empty();
  }
}

void main() {
  ProviderContainer container(
    Future<Map<String, String>> Function()? builder,
  ) {
    final c = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        if (builder != null)
          authHeadersBuilderProvider.overrideWithValue(builder),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('SseClient forwards the auth headers to the transport', () async {
    final transport = _RecordingTransport();
    final client = SseClient(
      baseUrl: 'http://localhost:8000',
      transport: transport,
      headers: () async => {'Authorization': 'Bearer tok-1'},
    );
    await client.chatStream(const ChatRequest(question: 'q')).toList();
    expect(transport.opens.single, {'Authorization': 'Bearer tok-1'});
  });

  test('SseClient without a builder opens headerless (compat mode)', () async {
    final transport = _RecordingTransport();
    final client = SseClient(
      baseUrl: 'http://localhost:8000',
      transport: transport,
    );
    await client.chatStream(const ChatRequest(question: 'q')).toList();
    expect(transport.opens.single, isNull);
  });

  test('AgentStreamClient forwards the auth headers to the transport',
      () async {
    final transport = _RecordingTransport();
    final client = AgentStreamClient(
      baseUrl: 'http://localhost:8000',
      transport: transport,
      headers: () async => {'Authorization': 'Bearer tok-2'},
    );
    await client
        .run(Uri.parse('http://localhost:8000/api/v1/documents/d1/summary'))
        .toList();
    expect(transport.opens.single, {'Authorization': 'Bearer tok-2'});
  });

  test('authHeadersBuilderProvider is null unless overridden (compat wiring)',
      () {
    expect(container(null).read(authHeadersBuilderProvider), isNull);
  });
}
