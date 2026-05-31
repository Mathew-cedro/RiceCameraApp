import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_analyzer.dart';

class AnalysisProvider with ChangeNotifier {
  final PalayApiService _apiService = PalayApiService();

  bool _isLoading = false;
  AnalysisResult? _lastResult; 
  File? _selectedImage;

  bool get isLoading => _isLoading;
  AnalysisResult? get lastResult => _lastResult;
  File? get selectedImage => _selectedImage;

  Future<void> analyzeImage(File image) async {
    _isLoading = true;
    _selectedImage = image;
    _lastResult = null;
    notifyListeners();

    final result = await _apiService.uploadAndAnalyze(image);

    _lastResult = result;
    _isLoading = false;
    notifyListeners();
  }
}