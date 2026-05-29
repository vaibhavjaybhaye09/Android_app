import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/dio_client.dart';
import '../models/photographer_model.dart';
import '../models/booking_model.dart';
import '../models/post_model.dart';
import '../models/service_model.dart';
import '../models/portfolio_item_model.dart';
import '../core/constants/api_constants.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  
  final String message;
  final int? statusCode;
  
  @override
  String toString() => message;
}

class ApiService {
  ApiService(this.dioClient);

  final DioClient dioClient;
  
  String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'Unauthorized. Please log in again.';
        } else if (statusCode == 403) {
          return 'Access denied.';
        } else if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return e.response?.data?.toString() ?? 'An error occurred';
      default:
        return e.message ?? 'An unexpected error occurred';
    }
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await dioClient.dio.get('${ApiConstants.profile}me/');
      return response.data;
    } on DioException catch (e) {
      throw ApiException(_getErrorMessage(e), e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      FormData formData = FormData();
      
      // Add all text fields to FormData
      data.forEach((key, value) {
        if (key != 'profile_picture' && key != 'skill_ids' && key != 'profile_picture_file') {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Handle skill_ids
      if (data.containsKey('skill_ids') && data['skill_ids'] is List) {
        for (var id in data['skill_ids']) {
          formData.fields.add(MapEntry('skill_ids', id.toString()));
        }
      }
      
      // Handle file upload
      if (data.containsKey('profile_picture_file') && data['profile_picture_file'] is XFile) {
        final XFile file = data['profile_picture_file'] as XFile;
        final bytes = await file.readAsBytes();
        
        formData.files.add(MapEntry(
          'profile_picture',
          MultipartFile.fromBytes(
            bytes,
            filename: file.name,
          ),
        ));
      }

      final response = await dioClient.dio.patch(
        '${ApiConstants.profile}me/', 
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException(_getErrorMessage(e), e.response?.statusCode);
    }
  }

  Future<List<dynamic>> getSkills() async {
    try {
      final response = await dioClient.dio.get('/api/auth/skills/');
      return response.data;
    } on DioException catch (e) {
      throw ApiException(_getErrorMessage(e), e.response?.statusCode);
    }
  }

  Future<List<PhotographerModel>> getPhotographers() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.photographers);
      final List<dynamic> data = response.data;
      return data.map((json) => PhotographerModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException(_getErrorMessage(e), e.response?.statusCode);
    }
  }

  Future<List<dynamic>> getNearbyFeed() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.nearbyFeed);
      return response.data;
    } on DioException catch (e) {
      throw ApiException(_getErrorMessage(e), e.response?.statusCode);
    }
  }

  Future<PhotographerModel> getPhotographerDetails(int id) async {
    try {
      final response = await dioClient.dio.get('${ApiConstants.photographers}$id/');
      return PhotographerModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load photographer details');
    }
  }

  Future<List<BookingModel>> getMyBookings() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.bookings);
      final List<dynamic> data = response.data;
      return data.map((json) => BookingModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load bookings');
    }
  }

  Future<BookingModel> createBooking({
    required int photographerId,
    required String date,
    String? notes,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.bookings,
        data: {
          'photographer_id': photographerId,
          'date': date,
          'notes': notes,
        },
      );
      return BookingModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to create booking');
    }
  }

  Future<List<dynamic>> getPortfolio() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.portfolio);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load portfolio');
    }
  }

  Future<List<PostModel>> getPhotographerPosts(int photographerId) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.posts,
        queryParameters: {'photographer': photographerId},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => PostModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load posts');
    }
  }

  Future<void> likePost(int postId) async {
    try {
      await dioClient.dio.post('${ApiConstants.posts}$postId/like/');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to like post');
    }
  }

  Future<Map<String, dynamic>> createPost({
    required XFile file,
    String? caption,
    String? location,
    String postType = 'image',
  }) async {
    try {
      FormData formData = FormData();
      if (caption != null) formData.fields.add(MapEntry('caption', caption));
      if (location != null) formData.fields.add(MapEntry('location', location));
      formData.fields.add(MapEntry('post_type', postType));

      final bytes = await file.readAsBytes();
      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      ));

      final response = await dioClient.dio.post(
        ApiConstants.posts,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data?.toString() ?? e.message;
      throw Exception('Failed to create post: $message');
    }
  }

  Future<Map<String, dynamic>> addComment(int postId, String text) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.comments,
        data: {'post_id': postId, 'text': text},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to add comment');
    }
  }

  Future<List<ServiceModel>> getServices() async {
    try {
      final response = await dioClient.dio.get('/api/auth/services/');
      final List<dynamic> data = response.data;
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load services');
    }
  }

  Future<ServiceModel> createService(ServiceModel service) async {
    try {
      final response = await dioClient.dio.post(
        '/api/auth/services/',
        data: service.toJson(),
      );
      return ServiceModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to create service');
    }
  }

  Future<PortfolioItemModel> addPortfolioItem({
    required XFile image,
    required String title,
    String? description,
  }) async {
    try {
      FormData formData = FormData();
      formData.fields.add(MapEntry('title', title));
      if (description != null) formData.fields.add(MapEntry('description', description));

      final bytes = await image.readAsBytes();
      formData.files.add(MapEntry(
        'image',
        MultipartFile.fromBytes(
          bytes,
          filename: image.name,
        ),
      ));

      final response = await dioClient.dio.post(
        ApiConstants.portfolio,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return PortfolioItemModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?.toString() ?? e.message;
      throw Exception('Failed to add portfolio item: $message');
    }
  }

  // Chat APIs
  Future<List<dynamic>> getConversations() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.conversations);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load conversations');
    }
  }

  Future<Map<String, dynamic>> createConversation(int participantId) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.conversations,
        data: {'participant_id': participantId},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to create conversation');
    }
  }

  Future<List<dynamic>> getMessages(int conversationId) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.messages,
        queryParameters: {'conversation': conversationId},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load messages');
    }
  }

  Future<Map<String, dynamic>> sendMessage(int conversationId, String text) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.messages,
        data: {
          'conversation': conversationId,
          'text': text,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to send message');
    }
  }
}
