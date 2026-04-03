from rest_framework import serializers
from django.conf import settings
from .models import (
    PhotographerProfile, Post, Comment, 
    Notification, Portfolio, Category, Story,
    Conversation, Message  # Import Conversation and Message
)
from accounts.serializers import UserSerializer


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ('id', 'name', 'slug')
        read_only_fields = ('id', 'slug')


class PhotographerProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True, required=False)
    followers_count = serializers.IntegerField(read_only=True)
    following_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = PhotographerProfile
        fields = (
            'id', 'user', 'user_id', 'display_name', 'profile_picture', 'bio',
            'website', 'location', 'phone_number', 'followers', 'following',
            'followers_count', 'following_count', 'total_likes_received',
            'total_views_received', 'is_verified_photographer', 'verification_badge',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'followers', 'following', 'created_at', 'updated_at')
    
    def create(self, validated_data):
        user = validated_data.pop('user_id', None)
        if user:
            validated_data['user'] = settings.AUTH_USER_MODEL.objects.get(id=user)
        return super().create(validated_data)


class PostSerializer(serializers.ModelSerializer):
    photographer = UserSerializer(read_only=True)
    photographer_id = serializers.IntegerField(write_only=True, required=False)
    likes_count = serializers.IntegerField(read_only=True)
    comments_count = serializers.IntegerField(read_only=True)
    is_liked_by_user = serializers.SerializerMethodField()
    
    class Meta:
        model = Post
        fields = (
            'id', 'photographer', 'photographer_id', 'image', 'caption', 'location',
            'likes', 'likes_count', 'comments_count', 'is_archived', 'is_liked_by_user',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'likes', 'created_at', 'updated_at')
    
    def get_is_liked_by_user(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(id=request.user.id).exists()
        return False
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['photographer'] = request.user
        elif validated_data.get('photographer_id'):
            validated_data['photographer'] = settings.AUTH_USER_MODEL.objects.get(
                id=validated_data.pop('photographer_id')
            )
        return super().create(validated_data)


class CommentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True, required=False)
    post_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = Comment
        fields = ('id', 'post', 'post_id', 'user', 'user_id', 'text', 'created_at')
        read_only_fields = ('id', 'created_at')
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['user'] = request.user
        elif validated_data.get('user_id'):
            validated_data['user'] = settings.AUTH_USER_MODEL.objects.get(
                id=validated_data.pop('user_id')
            )
        
        post_id = validated_data.pop('post_id')
        validated_data['post'] = Post.objects.get(id=post_id)
        
        return super().create(validated_data)


class MessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    sender_id = serializers.IntegerField(write_only=True, required=False)
    
    class Meta:
        model = Message
        fields = ('id', 'conversation', 'sender', 'sender_id', 'text', 'image', 'is_read', 'created_at')
        read_only_fields = ('id', 'created_at')
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['sender'] = request.user
        elif validated_data.get('sender_id'):
            validated_data['sender'] = settings.AUTH_USER_MODEL.objects.get(
                id=validated_data.pop('sender_id')
            )
        return super().create(validated_data)


class ConversationSerializer(serializers.ModelSerializer):
    participants = UserSerializer(many=True, read_only=True)
    last_message = serializers.SerializerMethodField()
    messages = MessageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Conversation
        fields = ('id', 'participants', 'last_message', 'messages', 'created_at', 'updated_at')
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def get_last_message(self, obj):
        last_msg = obj.messages.first()
        if last_msg:
            return MessageSerializer(last_msg).data
        return None


class NotificationSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    from_user = UserSerializer(read_only=True)
    
    class Meta:
        model = Notification
        fields = ('id', 'user', 'from_user', 'notification_type', 'post', 'is_read', 'created_at')
        read_only_fields = ('id', 'created_at')


class PortfolioSerializer(serializers.ModelSerializer):
    photographer = UserSerializer(read_only=True)
    photographer_id = serializers.IntegerField(write_only=True, required=False)
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = Portfolio
        fields = (
            'id', 'photographer', 'photographer_id', 'title', 'image', 
            'description', 'category', 'category_name', 'is_featured', 'created_at'
        )
        read_only_fields = ('id', 'created_at')
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['photographer'] = request.user
        elif validated_data.get('photographer_id'):
            validated_data['photographer'] = settings.AUTH_USER_MODEL.objects.get(
                id=validated_data.pop('photographer_id')
            )
        return super().create(validated_data)


class StorySerializer(serializers.ModelSerializer):
    photographer = UserSerializer(read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Story
        fields = ('id', 'photographer', 'media', 'media_type', 'is_active', 'created_at', 'expires_at')
        read_only_fields = ('id', 'created_at', 'expires_at')
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['photographer'] = request.user
        return super().create(validated_data)