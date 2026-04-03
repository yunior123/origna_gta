import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:origna_gta/utils/env_config.dart';

const _bootstrapAdminEmail = 'e2e-admin@test.origna.ca';
const _bootstrapAdminPassword = 'REDACTED_TEST_PASSWORD';

Future<void> ensureSeedUserEmailVerified(String email, String password) async {
  final env = EnvConfig();
  final adminToken = await _login(
    env.orignabaseUrl,
    _bootstrapAdminEmail,
    _bootstrapAdminPassword,
  ).then((value) => value.accessToken);
  final target = await _login(env.orignabaseUrl, email, password);

  if (target.emailVerified) {
    return;
  }

  final response = await http.patch(
    Uri.parse(
      '${env.orignabaseUrl}/admin/users/${Uri.encodeComponent(target.userId)}',
    ),
    headers: {
      'Authorization': 'Bearer $adminToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'email_verified': true}),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError(
      'Failed to mark $email verified: ${response.statusCode} ${response.body}',
    );
  }
}

Future<_LoginResult> _login(
  String baseUrl,
  String email,
  String password,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError(
      'Login failed for $email: ${response.statusCode} ${response.body}',
    );
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final token = body['access_token'] as String?;
  final user = body['user'] as Map<String, dynamic>?;
  final userId = user?['id'] as String?;
  if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
    throw StateError('Login response missing token or user id for $email');
  }

  return _LoginResult(
    accessToken: token,
    userId: userId,
    emailVerified: user?['email_verified'] == true,
  );
}

class _LoginResult {
  final String accessToken;
  final String userId;
  final bool emailVerified;

  const _LoginResult({
    required this.accessToken,
    required this.userId,
    required this.emailVerified,
  });
}
