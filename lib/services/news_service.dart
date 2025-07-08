import 'dart:convert';
import 'dart:developer' as dev;

import 'package:digifarmer/constants/constants.dart';
import 'package:http/http.dart' as http;

class NewsService {
  static const List<String> _farmingTopics = [
    'precision agriculture technology',
    'sustainable farming practices',
    'crop disease management',
    'agricultural market trends',
    'irrigation and water management',
    'soil health and fertility',
    'pest control and integrated pest management',
    'climate-smart agriculture',
    'agricultural policy and regulations',
    'farm equipment and machinery innovations',
    'organic farming methods',
    'agricultural finance and insurance',
    'post-harvest technology',
    'agricultural trade and exports',
    'rural development initiatives',
  ];

  Future<Map<String, dynamic>> fetchNews(int page) async {
    try {
      final articles = await _generateAgriculturalNews();

      return {
        'status': 'ok',
        'totalResults': articles.length,
        'articles': articles,
      };
    } catch (e) {
      dev.log('Error generating news with Gemini: $e');
      throw Exception('Failed to generate agricultural news');
    }
  }

  Future<List<Map<String, dynamic>>> _generateAgriculturalNews() async {
    final List<Map<String, dynamic>> articles = [];

    // Generate 6-8 diverse agricultural news articles
    for (int i = 0; i < 8; i++) {
      final topic = _farmingTopics[i % _farmingTopics.length];
      final article = await _generateSingleArticle(topic, i + 1);
      if (article != null) {
        articles.add(article);
      }
    }

    return articles;
  }

  Future<Map<String, dynamic>?> _generateSingleArticle(
    String topic,
    int articleNumber,
  ) async {
    try {
      final prompt = _buildNewsPrompt(topic);

      final response = await http.post(
        Uri.parse('$geminiAPIBaseURL$geminiAPIEndPoint?key=$geminiAPIKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final generatedText =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        return _parseGeneratedArticle(generatedText, topic, articleNumber);
      } else {
        dev.log('Gemini API error: ${response.statusCode} - ${response.body}');
        return _generateFallbackArticle(topic, articleNumber);
      }
    } catch (e) {
      dev.log('Error generating article for topic "$topic": $e');
      return _generateFallbackArticle(topic, articleNumber);
    }
  }

  String _buildNewsPrompt(String topic) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return '''
Generate a realistic agricultural news article about "$topic" in JSON format with the following structure:
{
  "title": "Compelling and informative title (max 100 characters)",
  "description": "Brief summary of the article (max 200 characters)",
  "content": "Full article content (300-500 words) with practical information for farmers",
  "author": "Professional agricultural journalist name",
  "source": "Agricultural publication or news source name"
}

Requirements:
- Make it relevant and practical for farmers
- Include specific data, trends, or actionable advice
- Use current date context: $dateStr
- Write in professional news style
- Focus on real-world agricultural challenges and solutions
- Avoid overly promotional language

Respond only with valid JSON, no additional text.
''';
  }

  Map<String, dynamic> _parseGeneratedArticle(
    String generatedText,
    String topic,
    int articleNumber,
  ) {
    try {
      // Extract JSON from the generated text
      final jsonStart = generatedText.indexOf('{');
      final jsonEnd = generatedText.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = generatedText.substring(jsonStart, jsonEnd);
        final articleData = json.decode(jsonStr);

        return _formatArticle(articleData, topic, articleNumber);
      }
    } catch (e) {
      dev.log('Error parsing generated article JSON: $e');
    }

    return _generateFallbackArticle(topic, articleNumber);
  }

  Map<String, dynamic> _formatArticle(
    Map<String, dynamic> articleData,
    String topic,
    int articleNumber,
  ) {
    final now = DateTime.now();
    final publishedAt =
        now.subtract(Duration(hours: articleNumber * 2)).toIso8601String();

    return {
      'source': {
        'id': 'agricultural-digest',
        'name': articleData['source'] ?? 'Agricultural Digest',
      },
      'author': articleData['author'] ?? 'Agricultural News Team',
      'title': articleData['title'] ?? _generateFallbackTitle(topic),
      'description':
          articleData['description'] ?? _generateFallbackDescription(topic),
      'url':
          'https://agricultural-digest.com/articles/${_generateSlug(articleData['title'] ?? topic)}',
      'urlToImage': _generateImageUrl(topic),
      'publishedAt': publishedAt,
      'content': articleData['content'] ?? _generateFallbackContent(topic),
    };
  }

  Map<String, dynamic> _generateFallbackArticle(
    String topic,
    int articleNumber,
  ) {
    final now = DateTime.now();
    final publishedAt =
        now.subtract(Duration(hours: articleNumber * 2)).toIso8601String();

    return {
      'source': {'id': 'agri-news', 'name': 'Agricultural News Network'},
      'author': 'Agricultural News Team',
      'title': _generateFallbackTitle(topic),
      'description': _generateFallbackDescription(topic),
      'url': 'https://agri-news.com/articles/${_generateSlug(topic)}',
      'urlToImage': _generateImageUrl(topic),
      'publishedAt': publishedAt,
      'content': _generateFallbackContent(topic),
    };
  }

  String _generateFallbackTitle(String topic) {
    final titles = {
      'precision agriculture technology':
          'Smart Farming Revolution: AI and IoT Transform Agricultural Practices',
      'sustainable farming practices':
          'Eco-Friendly Farming: New Techniques Boost Yields While Protecting Environment',
      'crop disease management':
          'Advanced Disease Detection Systems Help Farmers Protect Crop Health',
      'agricultural market trends':
          'Global Food Markets Show Strong Growth as Demand Increases',
      'irrigation and water management':
          'Water-Smart Farming: Innovative Irrigation Systems Save Resources',
      'soil health and fertility':
          'Soil Science Breakthrough: New Methods Improve Land Productivity',
    };

    return titles[topic] ??
        'Agricultural Innovation: Latest Developments in $topic';
  }

  String _generateFallbackDescription(String topic) {
    final descriptions = {
      'precision agriculture technology':
          'Farmers are adopting cutting-edge technology to optimize crop production and reduce environmental impact.',
      'sustainable farming practices':
          'New sustainable methods are helping farmers increase productivity while preserving natural resources.',
      'crop disease management':
          'Early detection and treatment systems are revolutionizing how farmers protect their crops from diseases.',
      'agricultural market trends':
          'Analysis of current market conditions and price trends affecting agricultural commodities.',
      'irrigation and water management':
          'Efficient water management systems are helping farmers cope with changing climate conditions.',
      'soil health and fertility':
          'Research reveals new approaches to maintaining and improving soil health for better crop yields.',
    };

    return descriptions[topic] ??
        'Latest insights and developments in $topic for modern farmers.';
  }

  String _generateFallbackContent(String topic) {
    return '''
Recent developments in $topic are creating new opportunities for farmers worldwide. Industry experts report significant advances in this area, with practical applications already showing promising results in field trials.

Agricultural researchers have identified key strategies that can help farmers improve their operations while maintaining sustainability. These innovations are particularly relevant for addressing current challenges in food production and environmental stewardship.

Farmers implementing these new approaches report improved efficiency and better outcomes. The technology and methods being developed are designed to be practical and cost-effective for farm operations of all sizes.

Industry analysts predict continued growth and innovation in this sector, with more solutions becoming available to farmers in the coming months. Early adopters are already seeing the benefits of these advancements in their daily operations.

For farmers interested in learning more about these developments, agricultural extension services and industry organizations are providing training and support to help with implementation.
''';
  }

  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .substring(0, title.length > 50 ? 50 : title.length);
  }

  String _generateImageUrl(String topic) {
    // Generate a relevant placeholder image URL based on topic
    final imageKeywords = {
      'precision agriculture technology': 'smart-farming-technology',
      'sustainable farming practices': 'sustainable-agriculture',
      'crop disease management': 'crop-health-monitoring',
      'agricultural market trends': 'agricultural-market',
      'irrigation and water management': 'irrigation-systems',
      'soil health and fertility': 'soil-health',
      'pest control and integrated pest management': 'pest-management',
      'climate-smart agriculture': 'climate-agriculture',
      'agricultural policy and regulations': 'agricultural-policy',
      'farm equipment and machinery innovations': 'farm-machinery',
      'organic farming methods': 'organic-farming',
      'agricultural finance and insurance': 'agricultural-finance',
      'post-harvest technology': 'post-harvest',
      'agricultural trade and exports': 'agricultural-trade',
      'rural development initiatives': 'rural-development',
    };

    final keyword = imageKeywords[topic] ?? 'agriculture';
    return 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800&h=400&fit=crop&crop=center&auto=format&q=80';
  }
}
