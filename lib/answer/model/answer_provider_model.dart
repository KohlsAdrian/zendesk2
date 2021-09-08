enum ARTICLE_REJECT_REASON {
  NOT_RELATED,
  RELATED_BUT_DIDNT_ANSWER,
  UNKNOWN,
}

class AnswerProviderModel {
  final String interactionAccessToken;
  final int deflectionId;
  final String description;
  final Iterable<ArticleModel> articles;

  AnswerProviderModel(
    this.interactionAccessToken,
    this.deflectionId,
    this.description,
    this.articles,
  );

  factory AnswerProviderModel.fromJson(Map map) {
    String interactionAccessToken = map['interactionAccessToken'];
    int deflectionId = map['deflectionId'];
    String description = map['description'] ?? '';
    Iterable<ArticleModel> articles = ((map['articles'] as Iterable?) ?? [])
        .map((a) => ArticleModel.fromJson(a));
    return AnswerProviderModel(
      interactionAccessToken,
      deflectionId,
      description,
      articles,
    );
  }
}

/// Optimisation Note: 
/// 
/// ```articleId``` and ```deflectionArticleId``` are necessary 
/// to be String because Android Zendesk SDK uses `Long` datatype to resolve/reject
/// articles, so we use String and convert it to Long on Android side and we don't
/// lose information on retreving from native side
/// 
/// iOS uses Int64, but we are using String to make it compatible on both platforms
class ArticleModel {
  final String deflectionArticleId;
  final int brandId;
  final String articleId;
  final String body;
  final String htmlURL;
  final Iterable<String> labels;
  final String locale;
  final double score;
  final String snippet;
  final String title;
  final String url;

  ArticleModel(
    this.deflectionArticleId,
    this.brandId,
    this.articleId,
    this.body,
    this.htmlURL,
    this.labels,
    this.locale,
    this.score,
    this.snippet,
    this.title,
    this.url,
  );

  factory ArticleModel.fromJson(Map map) {
    String deflectionArticleId = map['deflectionArticleId'];
    int brandId = map['brandId'];
    String articleId = map['articleId'];
    String body = map['body'] ?? '';
    String htmlURL = map['htmlURL'];
    Iterable<String> labels = ((map['labels'] ?? []) as Iterable).map((e) => e);
    String locale = map['locale'];
    double score = map['score'];
    String snippet = map['snippet'];
    String title = map['title'];
    String url = map['url'];

    return ArticleModel(
      deflectionArticleId,
      brandId,
      articleId,
      body,
      htmlURL,
      labels,
      locale,
      score,
      snippet,
      title,
      url,
    );
  }
}
