import 'package:flutter/services.dart';

class Zendesk {
  Zendesk._();
  static Zendesk instance = Zendesk._();

  final MethodChannel channel = const MethodChannel('zendesk2');

  bool _answerInitialized = false;
  bool _chatInitialized = false;

  /// Initialize the Zendesk Answer SDK
  ///
  /// ```accountKey``` the zendesk created account key, unique by organization
  ///
  /// ```clientId``` your company Zendesk client ID
  ///
  /// ```zendeskUrl``` your company Zendesk domain URL
  Future<void> initAnswerSDK(
    String accountKey,
    String clientId,
    String zendeskUrl,
  ) async {
    if (_answerInitialized) return;
    Map arguments = {
      'accountKey': accountKey,
      'clientId': clientId,
      'zendeskUrl': zendeskUrl,
    };
    try {
      await channel.invokeMethod('init_answer', arguments);
      _answerInitialized = true;
    } catch (e) {
      print(e);
    }
  }

  /// Initialize the Zendesk Chat SDK
  ///
  /// ```accountKey``` the zendesk created account key, unique by organization
  ///
  /// ```appId``` the app ID created on Zendesk Panel
  Future<void> initChatSDK(
    String accountKey,
    String appId,
  ) async {
    if (_chatInitialized) return;
    Map arguments = {
      'accountKey': accountKey,
      'appId': appId,
    };
    try {
      await channel.invokeMethod('init_chat', arguments);
      _chatInitialized = true;
    } catch (e) {
      print(e);
    }
  }
}
