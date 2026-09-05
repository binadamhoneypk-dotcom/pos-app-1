import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Local (offline) password hashing. This is what lets a user log in with
/// no internet connection — we never depend on the server to check a
/// password. The server independently validates the same hash on sync.
///
/// NOTE: SHA-256 with a per-app pepper is adequate for a local device
/// store; if you later want server-side password storage too, hash again
/// server-side with bcrypt/argon2 — never store this raw hash as the
/// server's copy of the password.
class PasswordHelper {
  PasswordHelper._();

  static const _pepper = 'pos_app_local_pepper_v1'; // change per deployment

  static String hash(String plainPassword) {
    final bytes = utf8.encode(plainPassword + _pepper);
    return sha256.convert(bytes).toString();
  }

  static bool verify(String plainPassword, String storedHash) {
    return hash(plainPassword) == storedHash;
  }
}
