import 'package:knowledge_base_flutter/features/chat/chat_repository.dart';
import 'package:knowledge_base_flutter/shared/models/chat.dart';
import 'package:knowledge_base_flutter/shared/models/search.dart';

import '../search/stub_search_repository.dart';

/// In-memory [ChatRepository] for provider/widget tests: the handler decides
/// the returned event stream, every call is recorded. Not a `_test.dart`
/// file so several test suites can share it.
class StubChatRepository implements ChatRepository {
  StubChatRepository({this.chatHandler});

  Stream<ChatEvent> Function(String question, int limit, String? sessionId)?
      chatHandler;

  final List<({String question, int limit, String? sessionId})> chatCalls = [];

  @override
  Stream<ChatEvent> chat({
    required String question,
    int limit = ChatRepository.defaultLimit,
    String? sessionId,
  }) {
    chatCalls.add((question: question, limit: limit, sessionId: sessionId));
    final handler = chatHandler;
    if (handler == null) {
      throw StateError('ChatRepository.chat called without a handler');
    }
    return handler(question, limit, sessionId);
  }
}

// --- Chat SSE event fixtures  ---

RunStarted runStarted({
  String runId = 'run-1',
  SearchMode mode = SearchMode.hybrid,
  String? sessionId,
}) {
  return RunStarted(runId: runId, mode: mode, sessionId: sessionId);
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
  String? sessionId,
}) {
  return ChatDone(
    runId: runId,
    outcome: outcome,
    toolCalls: toolCalls,
    latencyMs: latencyMs,
    sessionId: sessionId,
  );
}

ChatErrorEvent chatError({
  String code = 'llm_provider_error',
  String message = 'LLM provider is not configured',
}) {
  return ChatErrorEvent(code: code, message: message);
}

ChatStatusEvent statusEvent(ChatStatusPhase phase) =>
    ChatStatusEvent(phase: phase);

QueryRewrittenEvent queryRewritten({
  String original = '那它的缺点呢？',
  String rewritten = 'Redis 分布式锁的缺点是什么？',
}) {
  return QueryRewrittenEvent(original: original, rewritten: rewritten);
}

ToolCallStartedEvent toolCallStarted({
  String callId = 'call_1',
  String toolName = 'search_knowledge',
  Map<String, dynamic> args = const {'query': 'Redis 分布式锁的缺点', 'limit': 8},
}) {
  return ToolCallStartedEvent(callId: callId, toolName: toolName, args: args);
}

ToolCallFinishedEvent toolCallFinished({
  String callId = 'call_1',
  String toolName = 'search_knowledge',
  ChatToolStatus status = ChatToolStatus.success,
  double latencyMs = 142.5,
}) {
  return ToolCallFinishedEvent(
    callId: callId,
    toolName: toolName,
    status: status,
    latencyMs: latencyMs,
  );
}
