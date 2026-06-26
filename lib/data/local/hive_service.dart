import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

/// Handles Hive initialization: registering type adapters and opening
/// the boxes the app needs. Call [HiveService.init] once before runApp.
class HiveService {
  HiveService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MessageRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ChatSessionAdapter());
    }

    await Hive.openBox<ChatSession>(AppConstants.chatBoxName);
    await Hive.openBox<ChatMessage>(AppConstants.messageBoxName);
    await Hive.openBox(AppConstants.settingsBoxName);

    _initialized = true;
  }

  static Box<ChatSession> get chatBox =>
      Hive.box<ChatSession>(AppConstants.chatBoxName);

  static Box<ChatMessage> get messageBox =>
      Hive.box<ChatMessage>(AppConstants.messageBoxName);

  static Box get settingsBox => Hive.box(AppConstants.settingsBoxName);
}
