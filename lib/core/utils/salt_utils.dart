import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/app_constants.dart';

class SaltUtils {
  /// Get the SALT value (from constants, NOT from storage)
  static String getSalt() {
    return AppConstants.salt;
  }

  /// Verify that SALT is correctly calculated
  static bool verifySalt() {
    if (AppConstants.firstCommitHash.contains('UPDATE_ME') ||
        AppConstants.salt.contains('UPDATE_ME')) {
      print('⚠️  SALT not configured yet!');
      return false;
    }

    // Calculate what SALT should be
    final input = '${AppConstants.packageName}:${AppConstants.firstCommitHash}';
    final bytes = utf8.encode(input);
    final calculated = sha256.convert(bytes).toString();

    // Compare with stored SALT
    final isValid = calculated == AppConstants.salt;

    if (isValid) {
      print('✅ SALT is valid!');
    } else {
      print('❌ SALT is INVALID!');
      print('   Expected: $calculated');
      print('   Got: ${AppConstants.salt}');
    }

    return isValid;
  }

  /// Calculate what the SALT should be
  static String calculateSalt() {
    final input = '${AppConstants.packageName}:${AppConstants.firstCommitHash}';
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Hash data with SALT for metadata
  static String hashWithSalt(String data) {
    final salt = getSalt();
    final input = '$data:$salt';
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
