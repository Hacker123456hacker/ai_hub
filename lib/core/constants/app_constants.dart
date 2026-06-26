class AppConstants {
  AppConstants._();

  static const String appName = 'AI Hub';

  // Hive box names
  static const String chatBoxName = 'chats_box';
  static const String messageBoxName = 'messages_box';
  static const String settingsBoxName = 'settings_box';

  // Secure storage keys
  static const String openRouterApiKeyKey = 'openrouter_api_key';

  // Settings keys (stored in settingsBox)
  static const String themeModeKey = 'theme_mode';
  static const String selectedModelKey = 'selected_model';
  static const String temperatureKey = 'temperature';
  static const String maxTokensKey = 'max_tokens';

  // OpenRouter
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String openRouterChatEndpoint = '/chat/completions';
  static const String openRouterKeyValidateEndpoint = '/key';
  static const String openRouterModelsEndpoint = '/models';

  // Defaults
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 2048;
  static const String defaultModel = 'openai/gpt-4o-mini';
}

/// A small curated list of popular OpenRouter models shown by default in the
/// model picker. Phase 2+ can replace/augment this with a live fetch from
/// the /models endpoint.
class OpenRouterModels {
  OpenRouterModels._();

  static const List<Map<String, String>> popular = [
    {
      'id': 'openai/gpt-4o-mini',
      'name': 'GPT-4o Mini',
      'provider': 'OpenAI',
    },
    {
      'id': 'openai/gpt-4o',
      'name': 'GPT-4o',
      'provider': 'OpenAI',
    },
    {
      'id': 'anthropic/claude-3.5-sonnet',
      'name': 'Claude 3.5 Sonnet',
      'provider': 'Anthropic',
    },
    {
      'id': 'google/gemini-flash-1.5',
      'name': 'Gemini 1.5 Flash',
      'provider': 'Google',
    },
    {
      'id': 'deepseek/deepseek-chat',
      'name': 'DeepSeek Chat',
      'provider': 'DeepSeek',
    },
    {
      'id': 'meta-llama/llama-3.1-8b-instruct:free',
      'name': 'Llama 3.1 8B (Free)',
      'provider': 'Meta',
    },
    {
      'id': 'mistralai/mistral-7b-instruct:free',
      'name': 'Mistral 7B (Free)',
      'provider': 'Mistral',
    },
  ];
}
