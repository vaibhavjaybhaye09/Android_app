import 'package:intl/intl.dart';

class ConversationModel {
  final int id;
  final List<ChatUserModel> participants;
  final MessageModel? lastMessage;
  final List<MessageModel>? messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      participants: (json['participants'] as List)
          .map((p) => ChatUserModel.fromJson(p))
          .toList(),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'])
          : null,
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((m) => MessageModel.fromJson(m))
              .toList()
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  ChatUserModel getOtherParticipant(int currentUserId) {
    return participants.firstWhere((p) => p.id != currentUserId);
  }
}

class MessageModel {
  final int id;
  final int? conversationId;
  final ChatUserModel sender;
  final String? text;
  final String? image;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    this.conversationId,
    required this.sender,
    this.text,
    this.image,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation'],
      sender: ChatUserModel.fromJson(json['sender']),
      text: json['text'],
      image: json['image'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get formattedTime => DateFormat.jm().format(createdAt.toLocal());
}

class ChatUserModel {
  final int id;
  final String email;
  final String? displayName;
  final String? profilePicture;

  ChatUserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.profilePicture,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id'],
      email: json['email'],
      displayName: json['profile']?['display_name'],
      profilePicture: json['profile']?['profile_picture'],
    );
  }

  String get name => displayName ?? email.split('@')[0];
}
