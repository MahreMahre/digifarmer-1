import 'dart:convert';
import 'dart:developer';
import 'package:digifarmer/models/gemini_analysis_model.dart';
import 'package:digifarmer/services/gemini_service.dart';
import 'package:flutter/foundation.dart';

class GeminiProvider extends ChangeNotifier {
  bool _isAnalyzing = false;
  GeminiAnalysisModel? _analysis;
  String? _error;

  bool get isAnalyzing => _isAnalyzing;
  GeminiAnalysisModel? get analysis => _analysis;
  String? get error => _error;

  Future<void> analyzeDisease({
    required String diseaseName,
    required List<String> classLabels,
    required List<double> probabilityScores,
    required String detectedClass,
  }) async {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      log('Starting Gemini analysis for disease: $diseaseName');
      
      final result = await GeminiService.analyzeDisease(
        diseaseName: diseaseName,
        classLabels: classLabels,
        probabilityScores: probabilityScores,
        detectedClass: detectedClass,
      );

      if (result != null) {
        _analysis = result;
        log('Gemini analysis completed successfully');
      } else {
        _error = 'Failed to analyze disease. Please try again.';
        log('Gemini analysis returned null');
      }
    } catch (e) {
      _error = 'Error during analysis: ${e.toString()}';
      log('Error in Gemini analysis: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<bool> validateImageContainsLeaf(Uint8List imageBytes) async {
    try {
      log('Starting leaf validation with Gemini');
      
      // Convert the image bytes to base64
      final base64Image = base64Encode(imageBytes);
      
      final result = await GeminiService.validateImageContainsLeaf(base64Image);
      
      log('Leaf validation result: ${result ? 'Leaf detected' : 'No leaf detected'}');
      return result;
    } catch (e) {
      log('Error in leaf validation: $e');
      return false; // In case of error, we'll proceed with classification
    }
  }

  void clearAnalysis() {
    _analysis = null;
    _error = null;
    _isAnalyzing = false;
    notifyListeners();
  }
}
