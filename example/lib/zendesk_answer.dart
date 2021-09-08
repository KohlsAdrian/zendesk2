import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zendesk2/zendesk2.dart';

class ZendeskAnswerUI extends StatefulWidget {
  _ZendeskAnswerUI createState() => _ZendeskAnswerUI();
}

class _ZendeskAnswerUI extends State<ZendeskAnswerUI> {
  final _zAnswer = ZendeskAnswer.instance;

  StreamSubscription<AnswerProviderModel>? _subscritionProvidersDeflection;
  StreamSubscription<bool>? _subscritionProvidersResolveArticleDeflection;
  StreamSubscription<bool>? _subscritionProvidersRejectArticleDeflection;

  AnswerProviderModel? _answerProviderModel;
  List<ArticleModel> _articles = [];

  ArticleModel? _articleDeflection;

  final _tecQuery = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _subscritionProvidersDeflection = _zAnswer.providersDeflection
          .listen((answerProviderModel) => setState(() {
                _articleDeflection = null;
                _answerProviderModel = answerProviderModel;
                _articles = _answerProviderModel?.articles.toList() ?? [];
              }));
      _subscritionProvidersResolveArticleDeflection = _zAnswer
          .providersResolveArticleDeflection
          .listen((resolved) => resolved
              ? setState(
                  () => _articles.remove(_articleDeflection),
                )
              : {});
      _subscritionProvidersRejectArticleDeflection = _zAnswer
          .providersRejectArticleDeflection
          .listen((rejected) => rejected
              ? setState(
                  () => _articles.remove(_articleDeflection),
                )
              : {});
    });
  }

  Future<bool> _onWillPop() async {
    _subscritionProvidersDeflection?.cancel();
    _subscritionProvidersResolveArticleDeflection?.cancel();
    _subscritionProvidersRejectArticleDeflection?.cancel();
    return true;
  }

  void _query() => _zAnswer.query(_tecQuery.text);

  void _resolve(ArticleModel articleModel) {
    final deflectionId = articleModel.deflectionArticleId;
    final articleId = articleModel.articleId;
    final token = _answerProviderModel!.interactionAccessToken;
    _articleDeflection = articleModel;
    _zAnswer.resolveArticle(deflectionId, articleId, token);
  }

  void _reject(ArticleModel articleModel) {
    final deflectionId = articleModel.deflectionArticleId;
    final articleId = articleModel.articleId;
    final token = _answerProviderModel!.interactionAccessToken;
    _articleDeflection = articleModel;
    _zAnswer.rejectArticle(deflectionId, articleId, token);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text('Answer SDK')),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: size.width * 0.85,
                  child: TextField(controller: _tecQuery),
                ),
                IconButton(
                  onPressed: _query,
                  icon: Icon(Icons.search),
                ),
              ],
            ),
            Container(
              height: size.height * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  children: _articles.map(
                    (article) {
                      final title = article.title;
                      final snippet = article.snippet;
                      final url = article.url;
                      final score = article.score;
                      return Column(
                        children: [
                          ListTile(
                            title: Text('$title ($score)'),
                            subtitle: Text(snippet),
                            onTap: () => print(url),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                child: Text('Resolve Article'),
                                onPressed: () => _resolve(article),
                              ),
                              ElevatedButton(
                                child: Text('Reject Article'),
                                onPressed: () => _reject(article),
                              ),
                            ],
                          ),
                          Divider(),
                        ],
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
