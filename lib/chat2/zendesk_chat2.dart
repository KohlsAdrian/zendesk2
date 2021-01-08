import 'package:zendesk2/chat2/model/provider_model.dart';
import 'package:zendesk2/zendesk2.dart';

enum PRE_CHAT_FIELD_STATUS {
  OPTIONAL,
  HIDDEN,
  REQUIRED,
}

class Zendesk2Chat {
  Zendesk2Chat._();
  static final Zendesk2Chat instance = Zendesk2Chat._();

  static const _channel = const MethodChannel('zendesk2');

  StreamController<ProviderModel> _providersStream;

  Stream<ProviderModel> get providersStream =>
      _providersStream.stream.asBroadcastStream();

  Timer _getProvidersTimer;

  Future<void> init(
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

  Future<void> setVisitorInfo({
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

  Future<void> logger(bool enabled) async {
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

  Future<void> dispose() async {
    try {
      _getProvidersTimer?.cancel();
      await _providersStream.sink.close();
      await _providersStream.close();
      _providersStream = null;
      await _channel.invokeMethod('dispose');
    } catch (e) {
      print(e);
    }
  }

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
      await _channel.invokeMethod('startChat', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> startChatProviders(
      {Duration periodicRetrieve = const Duration(milliseconds: 300)}) async {
    try {
      if (_providersStream != null) {
        await _providersStream.sink.close();
        await _providersStream.close();
      }
      _providersStream = StreamController<ProviderModel>();
      await _channel.invokeMethod('startChatProviders');
      _getProvidersTimer =
          Timer.periodic(periodicRetrieve, (timer) => _getChatProviders());
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendMessage(String message) async {
    Map arguments = {
      'message': message,
    };
    try {
      await _channel.invokeMethod('sendMessage', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendTyping(bool isTyping) async {
    Map arguments = {
      'isTyping': isTyping,
    };
    try {
      await _channel.invokeMethod('sendIsTyping', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> endChat() async {
    try {
      await _channel.invokeMethod('endChat');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getChatProviders() async {
    final value = await _channel.invokeMethod('getChatProviders');
    if (value != null) {
      final providerModel = ProviderModel.fromJson(value);
      providerModel.logs.removeWhere((element) => element.chatLogType == null);
      _providersStream.add(providerModel);
    }
  }

  Future<void> sendFile(String path) async {
    Map arguments = {
      'file': path,
    };
    try {
      await _channel.invokeMethod('sendFile', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendRateComment(String comment) async {
    Map arguments = {
      'comment': comment,
    };
    try {
      await _channel.invokeMethod('sendRatingComment', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendRateReview(RATING rating) async {
    Map arguments = {
      'rating': rating.toString().replaceAll('RATING.', ''),
    };
    try {
      await _channel.invokeMethod('sendRatingReview', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<List<String>> getAttachmentExtensions() async {
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
}
