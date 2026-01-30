class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      orderId: map['order_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      text: map['text'],
      imageUrl: map['image_url'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'sender_id': senderId,
      'text': text,
      'image_url': imageUrl,
    };
  }
}
