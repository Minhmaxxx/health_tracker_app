import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/gemini_service.dart';

class ChatbotProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  
  List<MessageModel> _messages = [];
  bool _isTyping = false;
  String? _error;
  
  List<MessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  String? get error => _error;
  
  /// Gửi tin nhắn
  Future<void> sendMessage(String text, {String? userContext}) async {
    if (text.trim().isEmpty) return;
    
    // Reset error
    _error = null;
    
    // Thêm tin nhắn user
    _messages.add(MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    
    // Hiện typing indicator
    _isTyping = true;
    notifyListeners();
    
    try {
      // Gọi Gemini API
      final response = await _geminiService.sendMessage(
        text,
        userContext: userContext,
      );
      
      // Thêm tin nhắn AI
      _messages.add(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _error = 'Không thể kết nối. Vui lòng thử lại.';
      _messages.add(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '😔 Xin lỗi, tôi đang gặp sự cố kỹ thuật. Vui lòng thử lại sau nhé!',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }
  
  /// Xóa chat
  void clearChat() {
    _messages.clear();
    _geminiService.clearHistory();
    _error = null;
    notifyListeners();
  }
  
  /// Thêm tin nhắn chào mừng
  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(MessageModel(
        id: 'welcome',
        text: '''Xin chào! 👋 Tôi là trợ lý sức khỏe của bạn.

Tôi có thể giúp bạn:
- 📊 Giải thích chỉ số BMI
- 🥗 Gợi ý thực đơn lành mạnh
- 💪 Tư vấn bài tập phù hợp
- 📈 Kế hoạch giảm/tăng cân

Hãy hỏi tôi bất cứ điều gì! 😊''',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  void initialize() {}
}