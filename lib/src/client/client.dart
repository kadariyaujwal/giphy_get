import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:giphy_get/src/client/models/gif.dart';
import 'package:giphy_get/src/client/models/languages.dart';
import 'package:giphy_get/src/client/models/rating.dart';
import 'package:giphy_get/src/client/models/type.dart';
import 'package:http/http.dart';

import 'models/collection.dart';

class GiphyClient {
  static final baseUri = Uri(scheme: 'https', host: 'api.giphy.com');

  final String _apiKey;
  final Client _client = Client();
  final String _random_id;
  final String _apiVersion = 'v1';
  final String _rating;
  final List<String> _filterWords;
  final List<String> _replaceWords;
  GiphyClient({
    required String apiKey,
    required String randomId,
    String? rating,
    List<String>? filterWords,
    List<String>? replaceWords,
  })  : _apiKey = apiKey,
        _rating = rating ?? GiphyRating.g,
        _filterWords = filterWords ?? [],
        _replaceWords = replaceWords ?? [],
        _random_id = randomId;

  Future<GiphyCollection> trending({
    int offset = 0,
    int limit = 30,
    String rating = GiphyRating.pg13,
    String lang = GiphyLanguage.english,
    String type = GiphyType.gifs,
  }) async {
    return _fetchCollection(
      baseUri.replace(
        path: '$_apiVersion/$type/trending',
        queryParameters: <String, String>{
          'offset': '$offset',
          'limit': '$limit',
          'rating': _rating,
          'lang': lang
        },
      ),
    );
  }

  Future<GiphyCollection> search(
    String query, {
    int offset = 0,
    int limit = 30,
    String rating = GiphyRating.pg13,
    String lang = GiphyLanguage.english,
    String type = GiphyType.gifs,
  }) async {
    if (_filterWords.contains(query)) {
      query = '';
      if(_replaceWords.isNotEmpty) {
        int randomIndex = Random().nextInt(_replaceWords.length);
        query = _replaceWords[randomIndex];
      }
      
    }

    return _fetchCollection(
      baseUri.replace(
        path: '$_apiVersion/$type/search',
        queryParameters: <String, String>{
          'q': query,
          'offset': '$offset',
          'limit': '$limit',
          'rating': _rating,
          'lang': lang,
        },
      ),
    );
  }

  Future<GiphyCollection> emojis({
    int offset = 0,
    int limit = 30,
    String rating = GiphyRating.pg13,
    String lang = GiphyLanguage.english,
  }) async {
    return _fetchCollection(
      baseUri.replace(
        path: '$_apiVersion/${GiphyType.emoji}',
        queryParameters: <String, String>{
          'offset': '$offset',
          'limit': '$limit',
          'rating': _rating,
          'lang': lang,
        },
      ),
    );
  }

  Future<GiphyGif> random({
    required String tag,
    String rating = GiphyRating.pg13,
    String type = GiphyType.gifs,
  }) async {
    return _fetchGif(
      baseUri.replace(
        path: '$_apiVersion/$type/random',
        queryParameters: <String, String>{
          'tag': tag,
          'rating': _rating,
        },
      ),
    );
  }

  Future<GiphyGif> byId(String id) async =>
      _fetchGif(baseUri.replace(path: 'v1/gifs/$id'));

  Future<String> getRandomId() async =>
      _getRandomId(baseUri.replace(path: 'v1/randomid'));

  Future<GiphyGif> _fetchGif(Uri uri) async {
    final response = await _getWithAuthorization(uri);

    return GiphyGif.fromJson((json.decode(response.body)
        as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<GiphyCollection> _fetchCollection(Uri uri) async {
    final response = await _getWithAuthorization(uri);

    return GiphyCollection.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<String> _getRandomId(Uri uri) async {
    final response = await _getWithAuthorization(uri);
    var decoded = json.decode(response.body);
    return decoded["data"]["random_id"];
  }

  Future<Response> _getWithAuthorization(Uri uri) async {
    Map<String, String> queryParams = Map.from(uri.queryParameters)
      ..putIfAbsent('api_key', () => _apiKey)
      ..putIfAbsent('random_id', () => _random_id);

    final response =
        await _client.get(uri.replace(queryParameters: queryParams));

    if (response.statusCode == 200) {
      return response;
    } else {
      throw GiphyClientError(response.statusCode, response.body);
    }
  }
}

class GiphyClientError {
  final int statusCode;
  final String exception;

  GiphyClientError(this.statusCode, this.exception);

  @override
  String toString() {
    return 'GiphyClientError{statusCode: $statusCode, exception: $exception}';
  }
}
