import 'package:knowledge_base_flutter/features/chat/chat_repository.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

import '../search/stub_search_repository.dart';

/// In-memory [ChatRepository] for provider/widget tests: the handler decides
/// the returned event stream, every call is recorded. Not a `_test.dart`
/// file so several test suites can share it.
class StubChatRepository implements ChatRepository {
  StubChatRepository({this.chatHandler});

  Stream<ChatEvent> Function(String question, int limit)? chatHandler;

  final List<({String question, int limit})> chatCalls = [];

  @override
  Stream<ChatEvent> chat({
    required String question,
    int limit = ChatRepository.defaultLimit,
  }) {
    chatCalls.add((question: question, limit: limit));
    final handler = chatHandler;
    if (handler == null) {
      throw StateError('ChatRepository.chat called without a handler');
    }
    return handler(question, limit);
  }
}

// --- Chat SSE event fixtures  ---

RunStarted runStarted({
  String runId = 'run-1',
  SearchMode mode = SearchMode.hybrid,
}) {
  return RunStarted(runId: runId, mode: mode);
}

SourcesEvent sourcesEvent({List<SearchHit>? items}) {
  return SourcesEvent(items: items ?? [searchHit(documentId: 'a')]);
}

AnswerDelta answerDelta(String text) => AnswerDelta(text: text);

ChatDone chatDone({
  String runId = 'run-1',
  String outcome = 'success',
  int toolCalls = 1,
  double latencyMs = 2300,
}) {
  return ChatDone(
    runId: runId,
    outcome: outcome,
    toolCalls: toolCalls,
    latencyMs: latencyMs,
  );
}

ChatErrorEvent chatError({
  String code = 'llm_provider_error',
  String message = 'LLM provider is not configured',
}) {
  return ChatErrorEvent(code: code, message: message);
}
