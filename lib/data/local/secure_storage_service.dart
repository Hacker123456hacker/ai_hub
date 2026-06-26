import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Wraps flutter_secure_storage to keep API keys out of plain Hive boxes.
/// On Android this uses the Keystore-backed EncryptedSharedPreferences.
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static Future<void> saveOpenRouterKey(String key) async {
    await _storage.write(
      key: AppConstants.openRouterApiKeyKey,
      value: key,
    );
  }

  static Future<String?> getOpenRouterKey() async {
    return _storage.read(key: AppConstants.openRouterApiKeyKey);
  }

  static Future<void> deleteOpenRouterKey() async {
    await _storage.delete(key: AppConstants.openRouterApiKeyKey);
  }
}
