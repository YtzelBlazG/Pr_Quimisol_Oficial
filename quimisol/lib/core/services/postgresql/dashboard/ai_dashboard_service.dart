import 'dart:convert';
import 'package:http/http.dart' as http;

class AiDashboardService {
  final String baseUrl;
  AiDashboardService({required this.baseUrl});

  Future<AiReport> generateExecutiveReport(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/ai/dashboard/report');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return AiReport.fromJson(j);
    }
    throw Exception('IA report failed (${res.statusCode})');
  }

  Future<AiIrregularities> analyzeIrregularities(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/ai/dashboard/irregularities');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return AiIrregularities.fromJson(j);
    }
    throw Exception('IA irregularities failed (${res.statusCode})');
  }

  Future<String> ask(String question, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/ai/dashboard/qa');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question, 'context': payload}));
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return (j['answer'] ?? '').toString();
    }
    throw Exception('IA Q&A failed (${res.statusCode})');
  }
}

class AiReport {
  final String summary; // texto del informe
  final List<String> highlights; // bullets
  AiReport({required this.summary, required this.highlights});
  factory AiReport.fromJson(Map j) => AiReport(
    summary: (j['summary'] ?? '').toString(),
    highlights: (j['highlights'] as List? ?? []).map((e) => e.toString()).toList(),
  );
}

class AiIrregularities {
  final List<String> issues;      // problemas/alertas
  final Map<String, dynamic> fixes; // sugerencias/acciones
  AiIrregularities({required this.issues, required this.fixes});
  factory AiIrregularities.fromJson(Map j) => AiIrregularities(
    issues: (j['issues'] as List? ?? []).map((e) => e.toString()).toList(),
    fixes: (j['fixes'] as Map? ?? const {}).cast<String, dynamic>(),
  );
}
