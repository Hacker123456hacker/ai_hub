import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/openrouter_service.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/local/secure_storage_service.dart';

// ---- Theme mode ----

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final saved = HiveService.settingsBox.get(AppConstants.themeModeKey);
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await HiveService.settingsBox.put(AppConstants.themeModeKey, value);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ---- OpenRouter API key state ----

enum ApiKeyStatus { notSet, validating, valid, invalid }

class ApiKeyState {
  final ApiKeyStatus status;
  final String? maskedKey;
  final String? errorMessage;
  final double? remainingCredits;

  const ApiKeyState({
    this.status = ApiKeyStatus.notSet,
    this.maskedKey,
    this.errorMessage,
    this.remainingCredits,
  });

  ApiKeyState copyWith({
    ApiKeyStatus? status,
    String? maskedKey,
    String? errorMessage,
    double? remainingCredits,
  }) {
    return ApiKeyState(
      status: status ?? this.status,
      maskedKey: maskedKey ?? this.maskedKey,
      errorMessage: errorMessage,
      remainingCredits: remainingCredits ?? this.remainingCredits,
    );
  }
}

class ApiKeyNotifier extends StateNotifier<ApiKeyState> {
  final OpenRouterService _service;

  ApiKeyNotifier(this._service) : super(const ApiKeyState()) {
    _loadSavedKey();
  }

  Future<void> _loadSavedKey() async {
    final key = await SecureStorageService.getOpenRouterKey();
    if (key != null && key.isNotEmpty) {
      state = state.copyWith(
        status: ApiKeyStatus.valid,
        maskedKey: _mask(key),
      );
      // Re-validate silently in the background.
      validateAndSave(key, persistOnInvalid: true);
    }
  }

  String _mask(String key) {
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 6)}••••••${key.substring(key.length - 4)}';
  }

  Future<bool> validateAndSave(
    String key, {
    bool persistOnInvalid = false,
  }) async {
    state = state.copyWith(status: ApiKeyStatus.validating);

    final result = await _service.validateKey(key);

    if (result.isValid) {
      await SecureStorageService.saveOpenRouterKey(key);
      state = ApiKeyState(
        status: ApiKeyStatus.valid,
        maskedKey: _mask(key),
        remainingCredits: result.remainingCredits,
      );
      return true;
    } else {
      if (persistOnInvalid) {
        // Key was previously saved but now fails validation (e.g. network
        // issue) — keep showing it as valid-but-unconfirmed rather than
        // wiping the user's saved key over a transient error.
        state = state.copyWith(status: ApiKeyStatus.valid);
      } else {
        state = ApiKeyState(
          status: ApiKeyStatus.invalid,
          errorMessage: result.errorMessage,
        );
      }
      return false;
    }
  }

  Future<void> clearKey() async {
    await SecureStorageService.deleteOpenRouterKey();
    state = const ApiKeyState(status: ApiKeyStatus.notSet);
  }

  Future<String?> getRawKey() => SecureStorageService.getOpenRouterKey();
}

final openRouterServiceProvider = Provider<OpenRouterService>((ref) {
  return OpenRouterService();
});

final apiKeyProvider =
    StateNotifierProvider<ApiKeyNotifier, ApiKeyState>((ref) {
  return ApiKeyNotifier(ref.watch(openRouterServiceProvider));
});

// ---- Selected model ----

class SelectedModelNotifier extends StateNotifier<String> {
  SelectedModelNotifier() : super(_loadInitial());

  static String _loadInitial() {
    return HiveService.settingsBox.get(
      AppConstants.selectedModelKey,
      defaultValue: AppConstants.defaultModel,
    ) as String;
  }

  Future<void> setModel(String modelId) async {
    state = modelId;
    await HiveService.settingsBox.put(AppConstants.selectedModelKey, modelId);
  }
}

final selectedModelProvider =
    StateNotifierProvider<SelectedModelNotifier, String>((ref) {
  return SelectedModelNotifier();
});

// ---- Temperature & max tokens ----

final temperatureProvider = StateProvider<double>((ref) {
  return HiveService.settingsBox.get(
    AppConstants.temperatureKey,
    defaultValue: AppConstants.defaultTemperature,
  ) as double;
});

final maxTokensProvider = StateProvider<int>((ref) {
  return HiveService.settingsBox.get(
    AppConstants.maxTokensKey,
    defaultValue: AppConstants.defaultMaxTokens,
  ) as int;
});
