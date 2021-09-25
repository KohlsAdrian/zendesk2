import 'dart:async';

import 'package:zendesk2/zendesk2.dart';

class ZendeskAnswer {
  ZendeskAnswer._() {
    _channel.setMethodCallHandler(
      (call) async {
        try {
          switch (call.method) {
            case 'sendAnswerProviderModel':
              final arguments = call.arguments;
              final answerProviderModel =
                  AnswerProviderModel.fromJson(arguments);
              _providersDeflection.sink.add(answerProviderModel);
              break;
            case 'sendResolveArticleDeflection':
              final success = call.arguments['success'] ?? false;
              _providersResolveArticleDeflection.sink.add(success);
              break;
            case 'sendRejectArticleDeflection':
              final success = call.arguments['success'] ?? false;
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
      StreamController();
  StreamController<bool> _providersResolveArticleDeflection =
      StreamController();
  StreamController<bool> _providersRejectArticleDeflection = StreamController();

  /// Retrieves `articles` and `interactionAccessToken` to resolve ou reject articles
  Stream<AnswerProviderModel> get providersDeflection =>
      _providersDeflection.stream.asBroadcastStream();

  /// Retrieves last `article` resolved success
  Stream<bool> get providersResolveArticleDeflection =>
      _providersResolveArticleDeflection.stream.asBroadcastStream();

  /// Retrieves last `article` rejected success
  Stream<bool> get providersRejectArticleDeflection =>
      _providersRejectArticleDeflection.stream.asBroadcastStream();

  bool _isStreaming = true;

  /// `query` key word or phrase to retrieve articles related
  ///
  /// result streams in `providersDeflection`
  Future<void> query(String query) async {
    if (!_isStreaming) {
      _providersDeflection = StreamController();
      _providersResolveArticleDeflection = StreamController();
      _providersRejectArticleDeflection = StreamController();
    }

    try {
      final arguments = {
        'query': query,
      };
      await _channel.invokeMethod('query', arguments);
    } catch (e) {
      print(e);
    }
  }

  /// User resolves article as helpful
  Future<void> resolveArticle(
    String deflectionArticleId,
    String articleId,
    String interactionAccessToken,
  ) async {
    try {
      final arguments = {
        'deflectionArticleId': deflectionArticleId,
        'articleId': articleId,
        'interactionAccessToken': interactionAccessToken,
      };
      await _channel.invokeMethod('resolve_article', arguments);
    } catch (e) {
      print(e);
    }
  }

  /// User resolves article as unhelpful
  ///
  /// `reason`: optional reason to rejection
  Future<void> rejectArticle(
    String deflectionArticleId,
    String articleId,
    String interactionAccessToken, {
    ARTICLE_REJECT_REASON reason = ARTICLE_REJECT_REASON.UNKNOWN,
  }) async {
    try {
      final arguments = {
        'deflectionArticleId': deflectionArticleId,
        'articleId': articleId,
        'interactionAccessToken': interactionAccessToken,
        'reason': reason.toString().split('.').last,
      };
      await _channel.invokeMethod('reject_article', arguments);
    } catch (e) {
      print(e);
    }
  }

  /// Release stream resources
  Future<void> dispose() async {
    await _providersDeflection.sink.close();
    await _providersDeflection.close();

    await _providersResolveArticleDeflection.sink.close();
    await _providersResolveArticleDeflection.close();

    await _providersRejectArticleDeflection.sink.close();
    await _providersRejectArticleDeflection.close();

    _isStreaming = false;
  }
}
