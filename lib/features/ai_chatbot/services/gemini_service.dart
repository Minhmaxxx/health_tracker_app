import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  ChatSession? _chat;

  // ✅ Cache để giảm API calls
  final Map<String, CachedResponse> _cache = {};

  /// Constructor - tự động load API key từ .env
  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 500,
      ),
      // ✅ Safety settings để tránh bị block
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
      ],
    );

    _initializeChat();
  }

  void _initializeChat() {
    _chat = _model.startChat(
      history: [
        Content.text(_getSystemPrompt()),
        Content.model([
          TextPart(
              'Xin chào! Tôi là trợ lý sức khỏe của bạn. Tôi có thể giúp gì cho bạn hôm nay? 😊')
        ]),
      ],
    );
  }

  String _getSystemPrompt() {
    return '''Bạn là trợ lý sức khỏe thông minh, chuyên về:
- Tính toán BMI, TDEE, calories
- Tư vấn dinh dưỡng, thực đơn
- Gợi ý bài tập thể dục
- Động viên người dùng

Phong cách trả lời:
✅ Ngắn gọn, dễ hiểu (max 150 từ)
✅ Dùng emoji phù hợp 😊💪🥗
✅ Tone thân thiện, động viên
✅ Có cấu trúc rõ ràng (bullet points nếu cần)
❌ KHÔNG đưa ra chẩn đoán y khoa
❌ KHÔNG khuyên dùng thuốc

Luôn nhắc: "Hãy tham khảo bác sĩ nếu cần tư vấn chuyên sâu."''';
  }

  /// Method cho HOME SCREEN với retry + cache + fallback
  Future<String> advise(
    Map<String, dynamic> profile,
    String question, {
    int maxRetries = 5,
  }) async {
    // ✅ 1. Check cache trước
    final cacheKey = _generateCacheKey(profile, question);
    final cached = _cache[cacheKey];

    if (cached != null && !cached.isExpired()) {
      print('✅ Using cached response');
      return cached.response;
    }

    final prompt = '''
Thông tin người dùng:
- Cân nặng: ${profile['weight']} kg
- Chiều cao: ${profile['height']} cm
- Hoạt động: ${profile['activity']}

Câu hỏi: $question

Trả lời ngắn gọn, thân thiện với emoji.
''';

    // ✅ 2. Retry với exponential backoff
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        final text = response.text ?? 'Xin lỗi, tôi không thể trả lời lúc này.';

        // ✅ Lưu vào cache (expire sau 1 giờ)
        _cache[cacheKey] = CachedResponse(
          response: text,
          timestamp: DateTime.now(),
        );

        return text;
      } catch (e) {
        print('Gemini API Error (attempt ${attempt + 1}/$maxRetries): $e');

        if (e.toString().contains('overloaded')) {
          if (attempt < maxRetries - 1) {
            // Exponential backoff: 3s → 6s → 9s → 12s → 15s
            final waitTime = 3 * (attempt + 1);
            print('⏳ Overloaded, retrying in ${waitTime}s...');
            await Future.delayed(Duration(seconds: waitTime));
            continue;
          }
          // ✅ 3. Fallback khi hết retry
          return _getFallbackResponse(question, profile);
        }

        if (e.toString().contains('not found')) {
          return '⚠️ Lỗi cấu hình model. Vui lòng cập nhật app.';
        }

        if (attempt == maxRetries - 1) {
          // ✅ Fallback khi hết retry
          return _getFallbackResponse(question, profile);
        }

        // Đợi trước khi retry
        await Future.delayed(Duration(seconds: 1));
      }
    }

    return _getFallbackResponse(question, profile);
  }

  /// Method cho CHATBOT SCREEN với retry
  Future<String> sendMessage(
    String message, {
    String? userContext,
    int maxRetries = 5,
  }) async {
    try {
      if (_chat == null) {
        _initializeChat();
      }

      String fullMessage = message;
      if (userContext != null && userContext.isNotEmpty) {
        fullMessage = 'Thông tin của tôi: $userContext\n\nCâu hỏi: $message';
      }

      // ✅ Retry với exponential backoff
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          final response = await _chat!.sendMessage(
            Content.text(fullMessage),
          );
          return response.text ?? 'Xin lỗi, tôi không thể trả lời lúc này.';
        } catch (e) {
          print('Gemini API Error (attempt ${attempt + 1}/$maxRetries): $e');

          if (e.toString().contains('overloaded')) {
            if (attempt < maxRetries - 1) {
              final waitTime = 3 * (attempt + 1);
              print('⏳ Overloaded, retrying in ${waitTime}s...');
              await Future.delayed(Duration(seconds: waitTime));
              continue;
            }
            throw Exception(
                'Hệ thống đang quá tải. Vui lòng thử lại sau 1-2 phút.');
          }

          if (e.toString().contains('not found')) {
            throw Exception('Lỗi cấu hình model. Vui lòng cập nhật app.');
          }

          if (attempt == maxRetries - 1) {
            throw Exception('Không thể kết nối. Vui lòng kiểm tra internet.');
          }

          await Future.delayed(Duration(seconds: 1));
        }
      }

      throw Exception('Không thể kết nối sau $maxRetries lần thử.');
    } catch (e) {
      print('Gemini API Error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Xóa lịch sử chat
  void clearHistory() {
    _initializeChat();
  }

  /// Xóa cache (optional - dùng khi cần làm mới)
  void clearCache() {
    _cache.clear();
  }

  /// Tạo cache key duy nhất
  String _generateCacheKey(Map<String, dynamic> profile, String question) {
    return '${question.toLowerCase().trim()}-${profile['weight']}-${profile['height']}';
  }

  /// ✅ Fallback responses khi API fail
  String _getFallbackResponse(String question, Map<String, dynamic> profile) {
    final q = question.toLowerCase();

    // BMI calculation
    if (q.contains('bmi') || q.contains('chỉ số')) {
      final weight = profile['weight'] as num? ?? 0;
      final height = profile['height'] as num? ?? 0;

      if (weight > 0 && height > 0) {
        final bmi = weight / ((height / 100) * (height / 100));
        String category = 'bình thường';
        String advice = '';

        if (bmi < 18.5) {
          category = 'thiếu cân';
          advice = '''💡 Gợi ý:
• Tăng cân lành mạnh
• Ăn nhiều protein (thịt, cá, trứng)
• Tập gym để tăng cơ''';
        } else if (bmi >= 25 && bmi < 30) {
          category = 'thừa cân';
          advice = '''💡 Gợi ý:
• Giảm cân an toàn 0.5kg/tuần
• Ăn thâm hụt 500 kcal/ngày
• Tập cardio 30 phút/ngày''';
        } else if (bmi >= 30) {
          category = 'béo phì';
          advice = '''💡 Gợi ý:
• Tham khảo bác sĩ/chuyên gia dinh dưỡng
• Giảm cân từ từ, an toàn
• Kết hợp ăn uống + vận động''';
        } else {
          advice = '''💡 Gợi ý:
• Duy trì cân nặng hiện tại
• Ăn cân đối dinh dưỡng
• Tập thể dục đều đặn''';
        }

        return '''📊 **Chỉ số BMI của bạn: ${bmi.toStringAsFixed(1)}**

Phân loại: $category

$advice

⚠️ Lưu ý: Đây là tính toán tự động khi hệ thống quá tải. Hãy tham khảo bác sĩ để được tư vấn chính xác.''';
      }
    }

    // Weight loss
    if (q.contains('giảm cân') || q.contains('giảm')) {
      return '''💪 **Kế hoạch giảm cân an toàn:**

1️⃣ **Dinh dưỡng:**
   • Thâm hụt 500 kcal/ngày
   • Ăn nhiều rau xanh, protein nạc
   • Tránh đồ chiên rán, nước ngọt

2️⃣ **Vận động:**
   • Cardio 30 phút/ngày (chạy, đạp xe)
   • Đi bộ 10,000 bước
   • Tập gym 3-4 lần/tuần

3️⃣ **Mục tiêu:**
   • Giảm 0.5kg/tuần
   • Kiên trì 2-3 tháng

🔥 Nhớ: Từ từ mà chắc!

⚠️ Hệ thống quá tải. Đây là hướng dẫn tự động.''';
    }

    // Weight gain
    if (q.contains('tăng cân') || q.contains('tăng')) {
      return '''💪 **Kế hoạch tăng cân lành mạnh:**

1️⃣ **Ăn nhiều hơn:**
   • Thặng dư 500 kcal/ngày
   • 6 bữa/ngày (3 chính + 3 phụ)
   • Nhiều protein (thịt, cá, trứng, sữa)

2️⃣ **Tập luyện:**
   • Gym/tập tạ 4-5 lần/tuần
   • Focus vào compound exercises
   • Tránh cardio quá nhiều

3️⃣ **Nghỉ ngơi:**
   • Ngủ 8 tiếng/đêm
   • Rest day 2-3 ngày/tuần

🍗 Ưu tiên tăng cơ, không phải mỡ!

⚠️ Hệ thống quá tải. Đây là hướng dẫn tự động.''';
    }

    // Exercise
    if (q.contains('tập') ||
        q.contains('exercise') ||
        q.contains('workout') ||
        q.contains('bài')) {
      return '''🏋️ **Lịch tập cho người mới:**

📅 **Tuần 1-2:**
• T2, T4, T6: Cardio 20 phút
• T3, T5, T7: Toàn thân 15 phút

📅 **Tuần 3-4:**
• T2: Chân + Bụng
• T3: Ngực + Vai  
• T4: Cardio 30 phút
• T5: Lưng + Tay
• T6: Full body
• T7: Nghỉ/đi bộ

💡 **Mẹo:**
✅ Khởi động 5 phút
✅ Uống đủ nước
✅ Nghỉ 48h giữa các nhóm cơ

⚠️ Hệ thống quá tải. Đây là hướng dẫn tự động.''';
    }

    // Nutrition/Diet
    if (q.contains('ăn') ||
        q.contains('thực đơn') ||
        q.contains('dinh dưỡng')) {
      return '''🥗 **Thực đơn cân bằng 1 ngày:**

🌅 **Sáng (7h):**
• 2 trứng + 2 lát bánh mì nguyên cám
• 1 cốc sữa tươi/sữa đậu nành
• 1 quả chuối

🌞 **Trưa (12h):**
• Cơm gạo lứt (1 chén)
• Ức gà/cá hồi nướng (100-150g)
• Rau xào/luộc
• Canh rau

🌙 **Tối (18h):**
• Salad rau trộn dầu olive
• Thịt bò/cá (100g)
• 1 quả táo/cam

🥜 **Snack (10h, 15h):**
• Hạnh nhân 20g
• Sữa chua Hy Lạp

⚠️ Hệ thống quá tải. Đây là hướng dẫn tự động.''';
    }

    // Default fallback
    return '''😔 **Hệ thống đang quá tải**

Xin lỗi bạn, do quá nhiều người sử dụng nên tôi không thể trả lời chi tiết lúc này.

💡 **Trong lúc chờ:**
• Uống 2-3 lít nước/ngày
• Đi bộ nhẹ 30 phút
• Ăn nhiều rau xanh
• Ngủ đủ 7-8 tiếng

🔄 **Vui lòng thử lại sau 2-3 phút!**

⚠️ Đây là phản hồi tự động khi hệ thống quá tải.''';
  }

  /// Tạo context từ profile người dùng
  static String buildUserContext({
    required int age,
    required double height,
    required double weight,
    required String gender,
    double? bmi,
    double? goalWeight,
  }) {
    String context = 'Tôi ${gender == 'male' ? 'nam' : 'nữ'}, '
        '$age tuổi, cao ${height.toStringAsFixed(0)}cm, '
        'nặng ${weight.toStringAsFixed(1)}kg';

    if (bmi != null) {
      context += ', BMI ${bmi.toStringAsFixed(1)}';
    }

    if (goalWeight != null) {
      context += ', mục tiêu ${goalWeight.toStringAsFixed(1)}kg';
    }

    return context;
  }
}

// ✅ Class lưu cache
class CachedResponse {
  final String response;
  final DateTime timestamp;

  CachedResponse({
    required this.response,
    required this.timestamp,
  });

  // Cache expire sau 1 giờ
  bool isExpired() {
    return DateTime.now().difference(timestamp).inHours >= 1;
  }
}
