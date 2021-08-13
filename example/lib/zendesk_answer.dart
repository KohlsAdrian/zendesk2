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
  bool? _resolved;
  bool? _rejected;

  final _tecQuery = TextEditingController();

  @override
  void initState() {
    _subscritionProvidersDeflection = _zAnswer.providersDeflection.listen(
        (answerProviderModel) =>
            setState(() => _answerProviderModel = answerProviderModel));
    _subscritionProvidersResolveArticleDeflection = _zAnswer
        .providersResolveArticleDeflection
        .listen((resolved) => setState(() => _resolved = resolved));
    _zAnswer.providersRejectArticleDeflection
        .listen((rejected) => setState(() => _rejected = rejected));
    super.initState();
  }

  Future<bool> _onWillPop() async {
    _subscritionProvidersDeflection?.cancel();
    _subscritionProvidersResolveArticleDeflection?.cancel();
    _subscritionProvidersRejectArticleDeflection?.cancel();
    await _zAnswer.dispose();
    return false;
  }

  void _query() => _zAnswer.query(_tecQuery.text);

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
                  children: (_answerProviderModel?.articles ?? []).map(
                    (article) {
                      final title = article.title;
                      final url = article.url;
                      final labels = article.labels;
                      final score = article.score;
                      return ListTile(
                        title: Text('$title ($score)'),
                        subtitle: Row(
                          children: labels
                              .map((l) =>
                                  Text(l + (labels.last == l ? '' : ', ')))
                              .toList(),
                        ),
                        onTap: () => print(url),
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
