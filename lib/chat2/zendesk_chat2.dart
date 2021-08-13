import 'dart:async';

import 'package:zendesk2/zendesk2.dart';

class Zendesk2Chat {
  Zendesk2Chat._() {
    _channel.setMethodCallHandler(
      (call) async {
        try {
          final arguments = call.arguments;
          switch (call.method) {
            case 'sendChatProvidersResult':
              final providerModel = ChatProviderModel.fromJson(arguments);
              _providersStream?.sink.add(providerModel);
              break;
            case 'sendChatConnectionStatusResult':
              CONNECTION_STATUS? connectionStatus;

              final mConnectionStatus = arguments['connectionStatus'];
              switch (mConnectionStatus) {
                case 'CONNECTED':
                  connectionStatus = CONNECTION_STATUS.CONNECTED;
                  break;
                case 'CONNECTING':
                  connectionStatus = CONNECTION_STATUS.CONNECTING;
                  break;
                case 'DISCONNECTED':
                  connectionStatus = CONNECTION_STATUS.DISCONNECTED;
                  break;
                case 'FAILED':
                  connectionStatus = CONNECTION_STATUS.FAILED;
                  break;
                case 'RECONNECTING':
                  connectionStatus = CONNECTION_STATUS.RECONNECTING;
                  break;
                case 'UNREACHABLE':
                  connectionStatus = CONNECTION_STATUS.UNREACHABLE;
                  break;
                default:
                  connectionStatus = CONNECTION_STATUS.UNKNOWN;
              }
              _connectionStatusStream?.sink.add(connectionStatus);
              break;
            case 'sendChatSettingsResult':
              ChatSettingsModel? chatSettingsModel =
                  ChatSettingsModel.fromJson(arguments);
              _chatSettingsStream?.sink.add(chatSettingsModel);
              break;
            case 'sendChatIsOnlineResult':
              final isOnline = arguments['isOnline'];
              _chatIsOnlineStream?.sink.add(isOnline);
              break;
          }
        } catch (e) {
          print(e);
        }
      },
    );
  }

  static final Zendesk2Chat instance = Zendesk2Chat._();

  static final _channel = Zendesk.instance.channel;

  /// added ignore so the source won't have warnings
  /// but don't forget to close or .dispose() when needed!!!
  /// ignore: close_sinks
  StreamController<ChatProviderModel>? _providersStream;
  StreamController<CONNECTION_STATUS>? _connectionStatusStream;
  StreamController<ChatSettingsModel>? _chatSettingsStream;
  StreamController<bool>? _chatIsOnlineStream;

  bool _isLoggerEnabled = false;
  bool _isStarted = false;

  /// Stream is triggered when socket receive new values
  ///
  /// Please see ```ChatProviderModel```
  Stream<ChatProviderModel>? get providersStream =>
      _providersStream?.stream.asBroadcastStream();

  /// Stream is triggered when socket receive new values
  ///
  /// ```CONNECTION_STATUS```:
  /// CONNECTED | CONNECTING | DISCONNECTED |
  /// FAILED | RECONNECTING | UNREACHABLE | UNKNOWN
  Stream<CONNECTION_STATUS>? get connectionStatusStream =>
      _connectionStatusStream?.stream.asBroadcastStream();

  /// Stream is triggered when socket receive new values
  ///
  /// Please see ```ChatSettingsModel```
  Stream<ChatSettingsModel>? get chatSettingsStream =>
      _chatSettingsStream?.stream.asBroadcastStream();

  /// Stream is triggered when socket receive new values
  ///
  /// Please see ```ChatAccountModel ```
  Stream<bool>? get chatIsOnlineStream =>
      _chatIsOnlineStream?.stream.asBroadcastStream();

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
    final arguments = {
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

  /// Closes connection and release resources
  Future<void> dispose() async {
    try {
      final result = await _channel.invokeMethod('chat_dispose');
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
      await _providersStream?.sink.close();
      await _connectionStatusStream?.sink.close();
      await _chatSettingsStream?.sink.close();
      await _chatIsOnlineStream?.sink.close();

      await _connectionStatusStream?.close();
      await _chatSettingsStream?.close();
      await _chatIsOnlineStream?.close();
      await _providersStream?.close();

      _providersStream = null;
      _chatSettingsStream = null;
      _chatIsOnlineStream = null;
      _providersStream = null;

      _isStarted = false;
    } catch (e) {
      print(e);
    }
  }

  /// Start chat providers for custom UI handling
  ///
  /// ```periodicRetrieve``` periodic time to update the ```providersStream```
  /// ```autoConnect``` Determines if you also want to connect to the chat socket
  /// The user will not receive push notifications while connected
  Future<void> startChatProviders({bool autoConnect = true}) async {
    try {
      if (_isStarted) {
        await dispose();
      }

      _providersStream = StreamController<ChatProviderModel>();
      _connectionStatusStream = StreamController<CONNECTION_STATUS>();
      _chatSettingsStream = StreamController<ChatSettingsModel>();
      _chatIsOnlineStream = StreamController<bool>();

      final result = await _channel.invokeMethod('startChatProviders');

      if (autoConnect) {
        await connect();
      }

      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }

      _isStarted = true;
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
    final arguments = {
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
    final arguments = {
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

  /// Providers only - send file
  ///
  /// ```path``` the file path, that will represent the file attachment on live chat
  Future<void> sendFile(String path) async {
    final arguments = {
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

  /// Register FCM Token for android push notifications
  Future<void> registerFCMToken(String token) async {
    try {
      final arguments = {
        'token': token,
      };
      final result = await _channel.invokeMethod('registerToken', arguments);
      if (_isLoggerEnabled) {
        print('zendesk2: $result');
      }
    } catch (e) {
      print(e);
    }
  }
}
