import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;

  ChatProvider(this._apiService);

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.getConversations();
      _conversations = data.map((json) => ConversationModel.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.getMessages(conversationId);
      _messages = data.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ConversationModel?> startConversation(int participantId) async {
    try {
      final data = await _apiService.createConversation(participantId);
      final conversation = ConversationModel.fromJson(data);
      
      // Update local conversations list
      final index = _conversations.indexWhere((c) => c.id == conversation.id);
      if (index != -1) {
        _conversations[index] = conversation;
      } else {
        _conversations.insert(0, conversation);
      }
      
      notifyListeners();
      return conversation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> sendMessage(int conversationId, String text) async {
    if (text.trim().isEmpty) return false;

    try {
      final data = await _apiService.sendMessage(conversationId, text);
      final newMessage = MessageModel.fromJson(data);
      
      _messages.add(newMessage);
      
      // Update last message in conversation list
      final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (convIndex != -1) {
        final updatedConv = ConversationModel(
          id: _conversations[convIndex].id,
          participants: _conversations[convIndex].participants,
          lastMessage: newMessage,
          messages: _conversations[convIndex].messages,
          createdAt: _conversations[convIndex].createdAt,
          updatedAt: DateTime.now(),
        );
        _conversations.removeAt(convIndex);
        _conversations.insert(0, updatedConv);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void addMessageLocally(MessageModel message) {
    _messages.add(message);
    notifyListeners();
  }
}
