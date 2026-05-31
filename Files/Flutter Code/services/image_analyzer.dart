import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 1. THE MODEL
class AnalysisResult {
  final String status;
  final String advice;
  final double ripePercent;
  final double yellowPercent;
  final double brownPercent;
  final Color statusColor;
  final IconData statusIcon;

  const AnalysisResult({
    required this.status,
    required this.advice,
    required this.ripePercent,
    required this.yellowPercent,
    required this.brownPercent,
    required this.statusColor,
    required this.statusIcon,
  });
}

// 2. THE SERVICE
class PalayApiService {
  static const String _url = "http://10.0.0.12:8000/analyze";

  Future<AnalysisResult?> uploadAndAnalyze(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_url));
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = json.decode(responseData.body);

        IconData icon;
        switch (data['iconType']) {
          case 'check':
            icon = Icons.check_circle_rounded;
            break;
          case 'time':
            icon = Icons.timelapse_rounded;
            break;
          case 'hourglass':
            icon = Icons.hourglass_bottom_rounded;
            break;
          default:
            icon = Icons.cancel_rounded;
        }

        String hexColor = data['statusColor'].replaceAll('#', '0xFF');
        Color color = Color(int.parse(hexColor));

        return AnalysisResult(
          status: data['status'],
          advice: data['advice'],
          ripePercent:
              (data['ripePercent'] as num).toDouble().clamp(0.0, 100.0),
          yellowPercent:
              (data['yellowPercent'] as num).toDouble().clamp(0.0, 100.0),
          brownPercent:
              (data['brownPercent'] as num).toDouble().clamp(0.0, 100.0),
          statusColor: color,
          statusIcon: icon,
        );
      }
    } catch (e) {
      debugPrint("Error calling API: $e");
    }
    return null;
  }
}
