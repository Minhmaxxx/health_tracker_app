class MessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  
  MessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}