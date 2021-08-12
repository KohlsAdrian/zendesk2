import 'package:flutter/services.dart';

class Zendesk {
  Zendesk._();
  static Zendesk instance = Zendesk._();

  static const _channel = const MethodChannel('zendesk2');

  /// Initialize the Zendesk SDK
  ///
  /// ```accountKey``` the zendesk created account key, unique by organization
  ///
  /// ```appId``` the app ID created on Zendesk Panel
  ///
  /// ```answerBot``` initialize the Answer BOT (default is false)
  ///
  Future<void> init(
    String accountKey,
    String appId, {
    bool answerBot = false,
  }) async {
    Map arguments = {
      'accountKey': accountKey,
      'appId': appId,
    };
    try {
      await _channel.invokeMethod('init', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> initChatSDK() async {
    try {
      await _channel.invokeMethod('init_chat');
    } catch (e) {
      print(e);
    }
  }

  Future<void> initAnswerSDK() async {
    try {
      await _channel.invokeMethod('init_answer');
    } catch (e) {
      print(e);
    }
  }
}
