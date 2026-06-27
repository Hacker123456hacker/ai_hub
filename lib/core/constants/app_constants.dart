class AppConstants {
  AppConstants._();

  static const String appName = 'AI Hub';

  // Hive box names
  static const String chatBoxName = 'chats_box';
  static const String messageBoxName = 'messages_box';
  static const String settingsBoxName = 'settings_box';

  // Secure storage keys
  static const String openRouterApiKeyKey = 'openrouter_api_key';

  // Settings keys
  static const String themeModeKey = 'theme_mode';
  static const String selectedModelKey = 'selected_model';
  static const String temperatureKey = 'temperature';
  static const String maxTokensKey = 'max_tokens';

  // OpenRouter — all endpoints verified against openrouter.ai/docs
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String openRouterChatEndpoint = '/chat/completions';
  // FIX: was '/key' which returns 404. Correct endpoint is '/auth/key'
  static const String openRouterKeyValidateEndpoint = '/auth/key';
  static const String openRouterModelsEndpoint = '/models';

  // Defaults
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 2048;
  static const String defaultModel = 'meta-llama/llama-3.1-8b-instruct:free';
}

class OpenRouterModels {
  OpenRouterModels._();

  // IDs verified against openrouter.ai/models (June 2026)
  static const List<Map<String, String>> popular = [
    {
      'id': 'meta-llama/llama-3.1-8b-instruct:free',
      'name': 'Llama 3.1 8B',
      'provider': 'Meta',
      'badge': 'FREE',
    },
    {
      'id': 'mistralai/mistral-7b-instruct:free',
      'name': 'Mistral 7B',
      'provider': 'Mistral',
      'badge': 'FREE',
    },
    {
      'id': 'deepseek/deepseek-r1:free',
      'name': 'DeepSeek R1',
      'provider': 'DeepSeek',
      'badge': 'FREE',
    },
    {
      'id': 'openai/gpt-4o-mini',
      'name': 'GPT-4o Mini',
      'provider': 'OpenAI',
      'badge': '',
    },
    {
      'id': 'openai/gpt-4o',
      'name': 'GPT-4o',
      'provider': 'OpenAI',
      'badge': '',
    },
    {
      'id': 'anthropic/claude-3.5-sonnet',
      'name': 'Claude 3.5 Sonnet',
      'provider': 'Anthropic',
      'badge': '',
    },
    {
      'id': 'google/gemini-2.0-flash-001',
      'name': 'Gemini 2.0 Flash',
      'provider': 'Google',
      'badge': '',
    },
    {
      'id': 'deepseek/deepseek-chat',
      'name': 'DeepSeek Chat',
      'provider': 'DeepSeek',
      'badge': '',
    },
  ];
}
