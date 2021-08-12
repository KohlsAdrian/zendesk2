import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zendesk2/chat2/model/provider_enums.dart';
import 'package:zendesk2/chat2/model/provider_model.dart';
import 'package:zendesk2/zendesk2.dart';

class Zendesk2Chat {
  Zendesk2Chat._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "sendChatProvidersResult") {
        if (_isLoggerEnabled)
          print('zendesk2 [sendChatProvidersResult]: ${call.arguments}');
        try {
          final providerModel = ProviderModel.fromJson(call.arguments);
          _providersStream?.sink.add(providerModel);
        } catch (e) {
          print(e);
        }
      }
    });
  }
  static final Zendesk2Chat instance = Zendesk2Chat._();

  static const _channel = const MethodChannel('zendesk2');

  // ignore: close_sinks
  StreamController<ProviderModel>? _providersStream;

  bool _isLoggerEnabled = false;

  /// Listen to all parameters of the connected Live Chat
  ///
  /// Stream is updated at Duration provided on ```startChatProviders```
  Stream<ProviderModel> get providersStream {
    _getChatProviders();
    return _providersStream!.stream.asBroadcastStream();
  }

  /// Initialize the Zendesk SDK
  ///
  /// ```accountKey``` the zendesk created account key, unique by organization
  ///
  /// ```appId``` the app ID created on Zendesk Panel
  ///
  /// ```iosThemeColor``` the Theme color for Native Chat on iOS (AppBar and chat bubbles)
  Future<void> init(
    String accountKey,
    String appId, {
    @Deprecated('Prefer to use custom UI chat providers')
        Color iosThemeColor = Colors.indigo,
  }) async {
    Map arguments = {
      'accountKey': accountKey,
      'appId': appId,
      'iosThemeColor': iosThemeColor.value,
    };
    try {
      final result = await _channel.invokeMethod('init', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Set on Native/Custom chat user information
  ///
  /// ```name``` The name of the user identified
  ///
  /// ```email``` The email of the user identified
  ///
  /// ```phoneNumber``` The phone number of the user identified
  ///
  /// ```departmentName``` The chat department for chat, usually this field is empty
  ///
  /// ```tags``` The list of tags to represent the chat context
  Future<void> setVisitorInfo({
    String name = '',
    String email = '',
    String phoneNumber = '',
    String departmentName = '',
    List<String> tags = const [],
  }) async {
    Map arguments = {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'departmentName': departmentName,
      'tags': tags,
    };
    try {
      final result = await _channel.invokeMethod('setVisitorInfo', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Set Native Chat parameters
  ///
  /// ```agentAvailability``` BOT tells if agent in available or not
  ///
  /// ```transcript``` If enabled user with provided email will receive the chat addressed to email
  ///
  /// ```preChatForm``` BOT request information of empty field on ```setVisitorInfo```
  ///
  /// ```offlineForms``` BOT request information to cache and will send as soon the user has connected ethernet
  ///
  /// ```nameFieldStatus``` if the BOT should ask about the user ```name```
  ///
  /// ```emailFieldStatus``` if the BOT should ask about the user ```email```
  ///
  /// ```phoneFieldStatus``` if the BOT should ask about the user ```phone```
  ///
  /// ```departmentFieldStatus``` if the BOT should ask about the user ```department``` to talk about
  ///
  /// ```endChatEnabled``` option to user end the chat
  ///
  /// ```transcriptChatEnabled``` option to user request chat transcription
  ///
  Future<void> customize({
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
      final result = await _channel.invokeMethod('customize', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// LOG events of the SDK
  ///
  /// ```enabled``` if enabled, shows detailed information about the SDK actions
  Future<void> logger(bool enabled) async {
    _isLoggerEnabled = enabled;
    Map arguments = {
      'enabled': enabled,
    };
    try {
      final result = await _channel.invokeMethod('logger', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Close connection and release resources
  Future<void> dispose() async {
    try {
      await _providersStream!.sink.close();
      await _providersStream!.close();
      _providersStream = null;
      final result = await _channel.invokeMethod('dispose');
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Start Native Chat with own bot behaviours
  ///
  /// ```toolbarTitle``` set toolbar title
  ///
  /// ```botLabel``` text to represent the BOT name
  ///
  /// ```backButtonLabel``` button text to represent iOS back button
  @Deprecated('Prefer to use the startChatProviders() method')
  Future<void> startChat({
    String toolbarTitle = 'Zendesk NativeChat',
    String botLabel = 'Z',
    String backButtonLabel = 'Back',
  }) async {
    Map arguments = {
      'toolbarTitle': toolbarTitle,
      'botLabel': botLabel,
      'backButtonLabel': backButtonLabel,
    };
    try {
      final result = await _channel.invokeMethod('startChat', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Start chat providers for custom UI handling
  ///
  /// ```periodicRetrieve``` periodic time to update the ```providersStream```
  /// ```connect``` Determines if you also want to connect the chat socket
  /// The user will not receive push notifications while connected
  Future<void> startChatProviders({bool connect = true}) async {
    try {
      if (_providersStream != null) {
        await _providersStream!.sink.close();
        await _providersStream!.close();
      }
      _providersStream = StreamController<ProviderModel>();
      final result = await _channel
          .invokeMethod('startChatProviders', {'connect': connect});

      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Mark the user as connected, Call this method if you did not connect while initializing startChatProviders or when resuming from background state.
  /// The user will also stop receiving push notifications for new messages.
  Future<void> connect() async {
    try {
      final result = await _channel.invokeMethod('connect');
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Disconect the web socket, important to call this to preserve battery power when app goes to background.
  ///  Usefull when going to background inside the chat screeen. The user will start receiving push notifications for new messages.
  Future<void> disconnect() async {
    try {
      final result = await _channel.invokeMethod('disconnect');
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Providers only - send message
  ///
  /// ```message``` the message text that represents on live chat
  Future<void> sendMessage(String message) async {
    Map arguments = {
      'message': message,
    };
    try {
      final result = await _channel.invokeMethod('sendMessage', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Providers only - update Zendesk panel if user is typing
  ///
  /// ```isTyping``` if true Zendesk panel will know that user is typing,
  /// otherwise not
  Future<void> sendTyping(bool isTyping) async {
    Map arguments = {
      'isTyping': isTyping,
    };
    try {
      final result = await _channel.invokeMethod('sendIsTyping', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Providers only - end the live chat
  Future<void> endChat() async {
    try {
      final result = await _channel.invokeMethod('endChat');
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Providers only - private function to update ```providersStream```
  Future<void> _getChatProviders() async {
    final value = await _channel.invokeMethod('getChatProviders');
    if (value != null) {
      final providerModel = ProviderModel.fromJson(value);
      _providersStream!.add(providerModel);
    }
  }

  /// Providers only - send file
  ///
  /// ```path``` the file path, that will represent the file attachment on live chat
  Future<void> sendFile(String path) async {
    Map arguments = {
      'file': path,
    };
    try {
      final result = await _channel.invokeMethod('sendFile', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }

  /// Providers only - retrieve all compatible file extensions for Zendesk live chat
  Future<List<String>?> getAttachmentExtensions() async {
    try {
      final value =
          await _channel.invokeMethod('compatibleAttachmentsExtensions');
      if (value != null && value is Iterable) {
        return value.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  /// Register FCM Token for android push notifications
  Future<void> registerFCMToken(String token) async {
    try {
      final result =
          await _channel.invokeMethod('registerToken', {"token": token});
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }
}
