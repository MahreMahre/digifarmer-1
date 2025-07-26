import 'dart:convert';

import 'package:digifarmer/constants/constants.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class NewsService {
  /// Fetches news data from local JSON file instead of API call
  Future<Map<String, dynamic>> fetchNews(int page) async {
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/njson.json',
      );

      // Parse the JSON string
      final Map<String, dynamic> jsonData =
          json.decode(jsonString) as Map<String, dynamic>;

      return jsonData;
    } catch (e) {
      throw Exception('Failed to load news data: ${e.toString()}');
    }
  }

  /// Original API call method - kept for reference
  Future<Map<String, dynamic>> fetchNewsFromAPI(int page) async {
    final response = await http.get(
      Uri.parse(
        '$newsAPIBaseURL$newsAPIEndPoint?q=farmers&sortBy=relevancy&page=$page&apiKey=$newsAPIKey',
      ),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 502) {
      throw Exception('No Internet Connection');
    } else {
      throw Exception('Failed to load news data');
    }
  }
}
