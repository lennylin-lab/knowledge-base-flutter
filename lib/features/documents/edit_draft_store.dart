import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Scope key of the create-mode editor draft (no document id yet).
const newDocumentDraftScopeKey = 'new';

/// One unsaved editor session, persisted under
/// `documents.edit_draft.<scopeKey>` (`scopeKey` = document id or
/// [newDocumentDraftScopeKey]).
///
/// [baselineContentHash] is the `content_hash` of the server document the
/// edits started from (null = unknown: old backend, pre-backfill row, or an
/// in-session save already nulled the guard). [baselineContent] is that same
/// server content captured verbatim; it backs the second restore tier — when
/// the hash is inconclusive, an exact string match against the freshly loaded
/// detail content proves the document did not change elsewhere. Drafts
/// persisted before [baselineContent] existed decode with a null value and
/// restore via the conservative conflict dialog. The client never computes
/// hashes itself.
@immutable
class EditDraft {
  const EditDraft({
    required this.scopeKey,
    required this.content,
    required this.titleOverride,
    required this.baselineContentHash,
    required this.baselineContent,
    required this.savedAt,
  });

  /// Document id, or [newDocumentDraftScopeKey] in create mode.
  final String scopeKey;

  /// Full Markdown buffer at persist time (front matter included).
  final String content;

  /// Title field value at persist time (may be whitespace; the empty string
  /// means "derive the title from the front matter").
  final String titleOverride;

  /// `content_hash` of the server document the edits started from; null when
  /// unknown (never synthesized — the client only relays server hashes).
  final String? baselineContentHash;

  /// Verbatim server content the edits started from (create mode: the
  /// template string); null only for drafts persisted before this field
  /// existed (missing JSON key decodes tolerantly to null).
  final String? baselineContent;

  final DateTime savedAt;

  factory EditDraft.fromJson(Map<String, dynamic> json) {
    return EditDraft(
      scopeKey: json['scopeKey'] as String,
      content: json['content'] as String,
      titleOverride: json['titleOverride'] as String? ?? '',
      baselineContentHash: json['baselineContentHash'] as String?,
      baselineContent: json['baselineContent'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'scopeKey': scopeKey,
    'content': content,
    'titleOverride': titleOverride,
    'baselineContentHash': baselineContentHash,
    'baselineContent': baselineContent,
    'savedAt': savedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is EditDraft &&
      other.scopeKey == scopeKey &&
      other.content == content &&
      other.titleOverride == titleOverride &&
      other.baselineContentHash == baselineContentHash &&
      other.baselineContent == baselineContent &&
      other.savedAt == savedAt;

  @override
  int get hashCode => Object.hash(
    scopeKey,
    content,
    titleOverride,
    baselineContentHash,
    baselineContent,
    savedAt,
  );
}

/// Best-effort local draft persistence on `shared_preferences`.
///
/// Deliberately survives logout (issue #5: the draft is what makes an expired
/// session non-fatal — the user re-logs in and the editor restores it), so
/// unlike theme/selection preferences there is no logout-side cleanup.
///
/// Every operation swallows storage failures: the draft is a safety net, and a
/// broken or unavailable store (e.g. web localStorage full) must never
/// interrupt editing — the in-memory buffers keep working.
class EditDraftStore {
  EditDraftStore({Future<SharedPreferences> Function()? prefsLoader})
    : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefsLoader;

  /// Skip persisting when the draft's content fields — the buffer plus its
  /// baseline copy — together exceed 1 MB (UTF-16 code units as a size
  /// proxy): web localStorage would overflow and thrash every keystroke. The
  /// session keeps working purely in memory in that case.
  static const maxPersistableContentLength = 1024 * 1024;

  static String _key(String scopeKey) => 'documents.edit_draft.$scopeKey';

  /// Loads the persisted draft for [scopeKey], or null when absent /
  /// unreadable / undecodable (all failures are silently swallowed).
  Future<EditDraft?> load(String scopeKey) async {
    try {
      final prefs = await _prefsLoader();
      final raw = prefs.getString(_key(scopeKey));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return EditDraft.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Persists [draft]; a no-op when the combined `content` +
  /// `baselineContent` size exceeds [maxPersistableContentLength]. Storage
  /// failures are swallowed.
  Future<void> save(EditDraft draft) async {
    final persistedLength =
        draft.content.length + (draft.baselineContent?.length ?? 0);
    if (persistedLength > maxPersistableContentLength) return;
    try {
      final prefs = await _prefsLoader();
      await prefs.setString(_key(draft.scopeKey), jsonEncode(draft.toJson()));
    } catch (_) {
      // Best-effort only (class doc): never surface storage failures.
    }
  }

  /// Removes the persisted draft for [scopeKey]. Storage failures swallowed.
  Future<void> clear(String scopeKey) async {
    try {
      final prefs = await _prefsLoader();
      await prefs.remove(_key(scopeKey));
    } catch (_) {
      // Best-effort only (class doc): never surface storage failures.
    }
  }
}
