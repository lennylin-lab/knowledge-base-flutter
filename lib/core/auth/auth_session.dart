import 'dart:convert';

/// The authenticated user's token set, persisted as one JSON blob.
///
/// The client treats the IdP as authoritative for authentication only:
/// [subject] is display/audit data peeked from the (unverified) JWT
/// payload — the server resolves membership from `sub` server-side
/// (identity-tenants.md §1), and no claim is ever used to authorize.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.subject,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String?,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    subject: json['subject'] as String?,
  );

  factory AuthSession.fromTokenResponse({
    required String accessToken,
    required Duration expiresIn,
    String? refreshToken,
    String? previousSubject,
  }) {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(expiresIn),
      subject: AuthSession.peekSubject(accessToken) ?? previousSubject,
    );
  }

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  /// Unverified JWT `sub` — never sent anywhere, never used for RBAC.
  final String? subject;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
    'subject': subject,
  };

  /// Whether [accessToken] can still be used without a refresh. One minute
  /// of skew keeps in-flight requests from expiring mid-call.
  bool isValidAt(DateTime now, {Duration skew = const Duration(minutes: 1)}) {
    return expiresAt.isAfter(now.add(skew));
  }

  /// Decodes the JWT payload's `sub` claim without verifying the signature
  /// (that is the resource server's job). Returns null on any surprise.
  static String? peekSubject(String accessToken) {
    final parts = accessToken.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      final sub = decoded is Map<String, dynamic> ? decoded['sub'] : null;
      return sub is String ? sub : null;
    } on FormatException {
      return null;
    }
  }
}
