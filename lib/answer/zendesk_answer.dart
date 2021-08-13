import 'dart:async';

import 'package:zendesk2/zendesk2.dart';

class ZendeskAnswer {
  ZendeskAnswer._() {
    _channel.setMethodCallHandler(
      (call) async {
        try {
          switch (call.method) {
            case 'sendDeflectionProvider':
              final arguments = call.arguments;
              final answerProviderModel =
                  AnswerProviderModel.fromJson(arguments);
              _providersDeflection.sink.add(answerProviderModel);
              break;
            case 'sendResolveArticleDeflectionProvider':
              final success = call.arguments['success'];
              _providersResolveArticleDeflection.sink.add(success);
              break;
            case 'sendRejectArticleProvider':
              final success = call.arguments['success'];
              _providersRejectArticleDeflection.sink.add(success);
              break;
          }
        } catch (e) {
          print(e);
        }
      },
    );
  }

  static final ZendeskAnswer instance = ZendeskAnswer._();

  static final _channel = Zendesk.instance.channel;

  StreamController<AnswerProviderModel> _providersDeflection =
      StreamController<AnswerProviderModel>();
  StreamController<bool> _providersResolveArticleDeflection =
      StreamController<bool>();
  StreamController<bool> _providersRejectArticleDeflection =
      StreamController<bool>();

  Stream<AnswerProviderModel> get providersDeflection =>
      _providersDeflection.stream.asBroadcastStream();

  Stream<bool> get providersResolveArticleDeflection =>
      _providersResolveArticleDeflection.stream.asBroadcastStream();

  Stream<bool> get providersRejectArticleDeflection =>
      _providersRejectArticleDeflection.stream.asBroadcastStream();

  Future<void> query(String query) async {
    try {
      final arguments = {
        'query': query,
      };
      await _channel.invokeMethod('query', arguments);
    } catch (e) {
      print(e);
    }
  }

  Future<void> dispose() async {
    _providersDeflection.sink.close();
    _providersDeflection.close();
    
    _providersResolveArticleDeflection.sink.close();
    _providersResolveArticleDeflection.close();

    _providersRejectArticleDeflection.sink.close();
    _providersRejectArticleDeflection.close();
  }
}
