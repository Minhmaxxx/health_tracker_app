import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  GeminiService(this.apiKey);

  static const _model = 'gemini-2.5-flash';
  static const _base  = 'generativelanguage.googleapis.com';
  static const _path  = '/v1/models/$_model:generateContent';

  Future<String> advise(
    Map<String, dynamic> profile,
    String? question,
  ) async {
    const system = '''
Bạn là trợ lý sức khỏe thân thiện, KHÔNG chẩn đoán y khoa.
Giảm cân an toàn: 0.5–1.0 kg/tuần; tăng cân: 0.25–0.5 kg/tuần.
Trả lời tiếng Việt, ngắn gọn, có gạch đầu dòng.
''';

    final userPrompt = '''
Hồ sơ: ${jsonEncode(profile)}
Câu hỏi: ${question?.trim().isEmpty ?? true ? "Gợi ý thực đơn + lịch tập hôm nay" : question!.trim()}
Yêu cầu: 3–6 gạch đầu dòng cụ thể; thêm "Mốc an toàn" nếu phù hợp.
''';

    final uri = Uri.https(_base, _path);
    final body = jsonEncode({
      "contents": [
        {"role": "user", "parts": [{"text": "$system\n$userPrompt"}]}
      ],
      "generationConfig": {"maxOutputTokens": 512, "temperature": 0.7}
    });

    // retry đơn giản cho 429/500/503
    const attempts = 3;
    Duration backoff = const Duration(milliseconds: 600);

    http.Response resp = http.Response('', 500);
    for (var i = 0; i < attempts; i++) {
      try {
        resp = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                // 'x-goog-api-key': apiKey, // dùng header, KHÔNG dùng ?key=
              },
              body: body,
            )
            .timeout(const Duration(seconds: 20));
      } on SocketException catch (e) {
        return 'Lỗi mạng: $e';
      } on HttpException catch (e) {
        return 'HTTP exception: $e';
      } on FormatException catch (e) {
        return 'Format exception: $e';
      } on TimeoutException {
        // sẽ retry
        resp = http.Response('{"error":"timeout"}', 408);
      }

      if (resp.statusCode == 200) break;
      if (![429, 500, 503].contains(resp.statusCode)) break;

      // đợi rồi thử lại
      await Future.delayed(backoff);
      backoff *= 2;
    }

    // log lỗi rõ ràng ra UI để biết chuyện gì
    if (resp.statusCode != 200) {
      return 'Lỗi (${resp.statusCode}): ${resp.body}';
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final cands = data['candidates'] as List?;
    final parts = (cands?[0]?['content']?['parts'] as List?) ?? [];
    final text = parts.map((p) => p['text'] as String? ?? '').join('\n').trim();
    return text.isEmpty ? 'Không nhận được phản hồi.' : text;
  }
}
