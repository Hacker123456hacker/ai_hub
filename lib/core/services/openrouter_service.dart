import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

class OpenRouterMessage {
  final String role;
  final String content;
  OpenRouterMessage({required this.role, required this.content});
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class KeyValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double? remainingCredits;
  KeyValidationResult({
    required this.isValid,
    this.errorMessage,
    this.remainingCredits,
  });
}

class OpenRouterService {
  final Dio _dio;

  OpenRouterService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.openRouterBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          // Only set non-content headers in base — Content-Type set per-request
          headers: {
            'HTTP-Referer': 'https://ai-hub.app',
            'X-Title': 'AI Hub',
          },
        ));

  Map<String, String> _authHeader(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  /// Validates key via GET /auth/key (correct OpenRouter endpoint)
  Future<KeyValidationResult> validateKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      return KeyValidationResult(
        isValid: false,
        errorMessage: 'API key cannot be empty',
      );
    }
    try {
      final response = await _dio.get(
        AppConstants.openRouterKeyValidateEndpoint,
        options: Options(headers: _authHeader(apiKey)),
      );
      if (response.statusCode == 200) {
        double? remaining;
        try {
          final limitRemaining =
              response.data['data']?['limit_remaining'];
          if (limitRemaining != null) {
            remaining = (limitRemaining as num).toDouble();
          }
        } catch (_) {}
        return KeyValidationResult(isValid: true, remainingCredits: remaining);
      }
      return KeyValidationResult(
        isValid: false,
        errorMessage: 'Unexpected status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return KeyValidationResult(
          isValid: false,
          errorMessage: 'Invalid API key — check and try again',
        );
      }
      // 404 here means endpoint moved — treat as network issue, not bad key
      if (e.response?.statusCode == 404) {
        return KeyValidationResult(
          isValid: true,
          errorMessage: null,
          remainingCredits: null,
        );
      }
      return KeyValidationResult(
        isValid: false,
        errorMessage: _friendlyError(e),
      );
    } catch (e) {
      return KeyValidationResult(isValid: false, errorMessage: e.toString());
    }
  }

  /// Streaming chat completion via SSE
  Stream<String> streamChatCompletion({
    required String apiKey,
    required String model,
    required List<OpenRouterMessage> messages,
    double temperature = AppConstants.defaultTemperature,
    int maxTokens = AppConstants.defaultMaxTokens,
  }) async* {
    // Pass Map directly — Dio encodes to JSON. Do NOT pre-encode with jsonEncode()
    // because double-encoding causes issues with some Dio versions.
    final body = {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    };

    final response = await _dio.post<ResponseBody>(
      AppConstants.openRouterChatEndpoint,
      data: body,
      options: Options(
        headers: _authHeader(apiKey),
        responseType: ResponseType.stream,
        // Allow 200 only — everything else throws so we get a clean DioException
        validateStatus: (status) => status == 200,
      ),
    );

    final stream = response.data!.stream;
    final lineBuffer = StringBuffer();

    await for (final bytes in stream) {
      lineBuffer.write(utf8.decode(bytes, allowMalformed: true));

      // Process complete SSE events (delimited by \n\n)
      while (true) {
        final raw = lineBuffer.toString();
        final idx = raw.indexOf('\n\n');
        if (idx == -1) break;

        final event = raw.substring(0, idx);
        lineBuffer
          ..clear()
          ..write(raw.substring(idx + 2));

        for (final line in event.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;
          final payload = trimmed.substring(5).trim();
          if (payload == '[DONE]') return;
          if (payload.isEmpty) continue;

          try {
            final decoded = jsonDecode(payload) as Map<String, dynamic>;
            final delta = decoded['choices']?[0]?['delta']?['content'];
            if (delta is String && delta.isNotEmpty) yield delta;
          } catch (_) {
            // Partial JSON chunk — will be completed in next iteration
          }
        }
      }
    }
  }

  String _friendlyError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        break;
    }
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['error']?['message'] ?? data['message'];
      if (msg != null) return msg.toString();
    }
    final status = e.response?.statusCode;
    if (status == 400) return 'Bad request — check your model selection.';
    if (status == 401) return 'Invalid API key.';
    if (status == 402) return 'Insufficient credits on your OpenRouter account.';
    if (status == 429) return 'Rate limit hit — wait a moment and try again.';
    if (status == 503) return 'OpenRouter is temporarily unavailable.';
    return e.message ?? 'Something went wrong (${status ?? 'unknown'})';
  }
}

// Extension to make stream errors catchable as clean Exceptions
extension OpenRouterServiceExt on OpenRouterService {
  Stream<String> streamWithCleanErrors({
    required String apiKey,
    required String model,
    required List<OpenRouterMessage> messages,
    double temperature = AppConstants.defaultTemperature,
    int maxTokens = AppConstants.defaultMaxTokens,
  }) async* {
    try {
      yield* streamChatCompletion(
        apiKey: apiKey, model: model, messages: messages,
        temperature: temperature, maxTokens: maxTokens,
      );
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }
}
