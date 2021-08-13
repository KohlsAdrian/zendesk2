import 'package:flutter/services.dart';
import 'package:zendesk2/chat2/zendesk_chat2.dart';

class Zendesk {
  Zendesk._();
  static Zendesk instance = Zendesk._();

  final MethodChannel channel = const MethodChannel('zendesk2');

  /// Initialize the Zendesk SDK
  ///
  /// ```accountKey``` the zendesk created account key, unique by organization
  ///
  /// ```appId``` the app ID created on Zendesk Panel
  ///
  /// ```answerBot``` and ```zendeskUrl``` are necessary for AnswerSDK
  Future<void> init(
    String accountKey,
    String appId, {
    String? clientId,
    String? zendeskUrl,
  }) async {
    Map arguments = {
      'accountKey': accountKey,
      'appId': appId,
      'clientId': clientId,
      'zendeskUrl': zendeskUrl,
    };
    try {
      await channel.invokeMethod('init', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> initChatSDK() async => await Zendesk2Chat.instance.init();
}
