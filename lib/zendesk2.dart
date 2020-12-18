import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

enum PRE_CHAT_FIELD_STATUS {
  OPTIONAL,
  HIDDEN,
  REQUIRED,
}

class Zendesk2 {
  static const _channel = const MethodChannel('zendesk2');

  static Future<void> init(
    String accountKey,
    String appId, {
    Color iosThemeColor,
    String firebaseToken,
  }) async {
    assert(accountKey != null);
    assert(appId != null);
    Map arguments = {
      'accountKey': accountKey,
      'appId': appId,
      if (iosThemeColor != null) 'iosThemeColor': iosThemeColor.value,
      if (firebaseToken != null) 'firebaseToken': firebaseToken,
    };
    try {
      await _channel.invokeMethod('init', arguments);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> setVisitorInfo({
    String name,
    String email,
    String phoneNumber,
    String departmentName,
    List<String> tags,
  }) async {
    Map arguments = {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (departmentName != null) 'departmentName': departmentName,
      if (tags != null) 'tags': tags,
    };
    try {
      await _channel.invokeMethod('setVisitorInfo', arguments);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> customize({
    bool agentAvailability = false,
    bool transcript = false,
    bool preChatForm = false,
    bool offlineForms = false,
    PRE_CHAT_FIELD_STATUS nameFieldStatus = PRE_CHAT_FIELD_STATUS.HIDDEN,
    PRE_CHAT_FIELD_STATUS emailFieldStatus = PRE_CHAT_FIELD_STATUS.HIDDEN,
    PRE_CHAT_FIELD_STATUS phoneFieldStatus = PRE_CHAT_FIELD_STATUS.HIDDEN,
    PRE_CHAT_FIELD_STATUS departmentFieldStatus = PRE_CHAT_FIELD_STATUS.HIDDEN,
    bool endChatEnabled = false,
    bool transcriptChatEnabled = false,
  }) async {
    assert(agentAvailability != null);
    assert(transcript != null);
    assert(preChatForm != null);
    assert(offlineForms != null);
    assert(nameFieldStatus != null);
    assert(emailFieldStatus != null);
    assert(phoneFieldStatus != null);
    assert(departmentFieldStatus != null);
    assert(endChatEnabled != null);
    assert(transcriptChatEnabled != null);

    Map arguments = {
      'agentAvailability': agentAvailability,
      'transcript': transcriptChatEnabled,
      'preChatForm': preChatForm,
      'offlineForms': offlineForms,
      'nameFieldStatus': nameFieldStatus
          .toString()
          .replaceAll('PRE_CHAT_FIELD_STATUS.', '')
          .toUpperCase(),
      'emailFieldStatus': emailFieldStatus
          .toString()
          .replaceAll('PRE_CHAT_FIELD_STATUS.', '')
          .toUpperCase(),
      'phoneFieldStatus': phoneFieldStatus
          .toString()
          .replaceAll('PRE_CHAT_FIELD_STATUS.', '')
          .toUpperCase(),
      'departmentFieldStatus': departmentFieldStatus
          .toString()
          .replaceAll('PRE_CHAT_FIELD_STATUS.', '')
          .toUpperCase(),
      'endChatEnabled': endChatEnabled,
      'transcriptChatEnabled': transcriptChatEnabled,
    };

    try {
      await _channel.invokeMethod('customize', arguments);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> logger(bool enabled) async {
    assert(enabled != null);
    Map arguments = {
      'enabled': enabled,
    };
    try {
      await _channel.invokeMethod('logger', arguments);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } catch (e) {
      print(e);
    }
  }

  static Future<void> startChat(
      {String toolbarTitle, String botLabel, String backButtonLabel}) async {
    Map arguments = {
      'toolbarTitle': toolbarTitle,
      'botLabel': botLabel,
      'backButtonLabel': backButtonLabel,
    };
    try {
      await _channel.invokeMethod('startChat', arguments);
    } catch (e) {
      print(e);
    }
  }
}
