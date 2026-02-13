import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/app_constants.dart';

class SaltUtils {
  // ======== Get stored SALT ========
  static String getSalt() {
    return AppConstants.salt;
  }

  //=========Create hash with SALT for metadata =====
  static String hashWithSalt(String data) {
    final salt = getSalt();
    final input = '$data:$salt';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
