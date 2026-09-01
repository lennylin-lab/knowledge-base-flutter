/// Disables Riverpod ≥3.3's default automatic provider retry (up to 10
/// attempts with exponential backoff): always answer "don't retry".
///
/// This app surfaces backend errors to the user in Chinese with an explicit
/// 重试 affordance (error-handling spec) instead: auto-retrying would hide
/// the error state from the user and actively re-hammer the backend on
/// 429 `rate_limited` responses, against the spec's "invite retry" intent.
///
/// The signature matches Riverpod's `Retry` callback (the typedef itself
/// is not exported by flutter_riverpod). Pass to `ProviderScope(retry:)`.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
