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

/// Result of validating an OpenRouter API key.
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

/// Thin client around the OpenRouter REST API.
/// Docs: https://openrouter.ai/docs
class OpenRouterService {
  final Dio _dio;

  OpenRouterService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.openRouterBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              headers: {
                'Content-Type': 'application/json',
                // OpenRouter requests these for analytics/rankings; optional
                // but recommended by their docs.
                'HTTP-Referer': 'https://ai-hub.app',
                'X-Title': 'AI Hub',
              },
            ));

  /// Validates an API key by hitting the lightweight /key endpoint, which
  /// returns account/key info without consuming a chat completion.
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
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        double? remaining;
        try {
          final limitRemaining = data['data']?['limit_remaining'];
          if (limitRemaining != null) {
            remaining = (limitRemaining as num).toDouble();
          }
        } catch (_) {
          // remaining credits not present; not fatal
        }
        return KeyValidationResult(isValid: true, remainingCredits: remaining);
      }

      return KeyValidationResult(
        isValid: false,
        errorMessage: 'Unexpected response: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return KeyValidationResult(
          isValid: false,
          errorMessage: 'Invalid API key',
        );
      }
      return KeyValidationResult(
        isValid: false,
        errorMessage: _dioErrorMessage(e),
      );
    } catch (e) {
      return KeyValidationResult(isValid: false, errorMessage: e.toString());
    }
  }

  /// Sends a chat completion request and streams back text chunks as they
  /// arrive via Server-Sent Events. Yields plain text deltas (already parsed
  /// out of the SSE `data: {...}` lines).
  Stream<String> streamChatCompletion({
    required String apiKey,
    required String model,
    required List<OpenRouterMessage> messages,
    double temperature = AppConstants.defaultTemperature,
    int maxTokens = AppConstants.defaultMaxTokens,
  }) async* {
    final requestBody = {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    };

    final response = await _dio.post<ResponseBody>(
      AppConstants.openRouterChatEndpoint,
      data: jsonEncode(requestBody),
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data!.stream;
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      final decoded = utf8.decode(chunk, allowMalformed: true);
      buffer.write(decoded);

      // SSE events are separated by double newlines.
      while (buffer.toString().contains('\n\n')) {
        final raw = buffer.toString();
        final idx = raw.indexOf('\n\n');
        final event = raw.substring(0, idx);
        buffer
          ..clear()
          ..write(raw.substring(idx + 2));

        for (final line in event.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;

          final payload = trimmed.substring(5).trim();
          if (payload == '[DONE]') return;
          if (payload.isEmpty) continue;

          try {
            final json = jsonDecode(payload);
            final delta = json['choices']?[0]?['delta']?['content'];
            if (delta != null && delta is String && delta.isNotEmpty) {
              yield delta;
            }
          } catch (_) {
            // Skip malformed SSE fragments (can happen mid-stream if a
            // chunk boundary splits a JSON object); next chunk usually
            // completes it.
          }
        }
      }
    }
  }

  /// Non-streaming chat completion, used as a simpler fallback if needed.
  Future<String> sendChatCompletion({
    required String apiKey,
    required String model,
    required List<OpenRouterMessage> messages,
    double temperature = AppConstants.defaultTemperature,
    int maxTokens = AppConstants.defaultMaxTokens,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.openRouterChatEndpoint,
        data: {
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': false,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );

      return response.data['choices'][0]['message']['content'] as String;
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e));
    }
  }

  String _dioErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your internet connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      final err = data['error'];
      if (err is Map && err['message'] != null) {
        return err['message'].toString();
      }
    }
    return e.message ?? 'Something went wrong';
  }
}
