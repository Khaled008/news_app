import 'package:dio/dio.dart';
import 'package:news_app/models/article_model.dart';

class NewsService {
  final Dio dio;
  NewsService(this.dio);

  Future<List<ArticleModel>> getTopHeadlines({required String category}) async {
    final Response response = await dio.get(
      'https://newsapi.org/v2/top-headlines',
      queryParameters: {
        'apiKey': 'ur api key',
        'category': category,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load news, code: ${response.statusCode}');
    }

    final Map<String, dynamic> jsonData = response.data as Map<String, dynamic>;
    final List<dynamic>? articles = jsonData['articles'] as List<dynamic>?;

    if (articles == null) return [];

    final List<ArticleModel> articlesList = [];

    for (var article in articles) {
      if (article == null || article is! Map<String, dynamic>) continue;

      final String title = (article['title'] ?? 'there is no title').toString();
      final String description =
          (article['description'] ?? 'there is no description').toString();
      final String image =
          (article['urlToImage'] ?? 'there is no image').toString();
      final String url = (article['url'] ?? '').toString();

   
      if ((title.isEmpty && description.isEmpty) || url.isEmpty) continue;

      articlesList.add(ArticleModel(
          image: image, title: title, subTitle: description, url: url));
    }

    return articlesList;
  }
}
