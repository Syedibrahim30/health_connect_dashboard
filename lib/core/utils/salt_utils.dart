import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/app_constants.dart';

class SaltUtils {
  static final _storage = GetStorage();

  /// Generate deterministic SALT from package name and first git commit hash
  /// SALT = SHA256("${packageName}:${firstGitCommitHash}")
  static String generateSalt({
    required String packageName,
    required String firstGitCommitHash,
  }) {
    final input = '$packageName:$firstGitCommitHash';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get stored SALT or generate new one
  static String getSalt() {
    String? storedSalt = _storage.read(StorageKeys.salt);

    if (storedSalt == null) {
      // TODO: Replace with actual values from git
      // This should be replaced with actual package name and first commit hash
      const packageName = 'com.example.health_connect_dashboard';
      const firstCommitHash =
          'Ifc931543b341c7f4ae50d48ddba95399365f4272'; // Will be replaced by actual git hash

      storedSalt = generateSalt(
        packageName: packageName,
        firstGitCommitHash: firstCommitHash,
      );

      _storage.write(StorageKeys.salt, storedSalt);
    }

    return storedSalt;
  }

  /// Create hash with SALT for metadata
  static String hashWithSalt(String data) {
    final salt = getSalt();
    final input = '$data:$salt';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
