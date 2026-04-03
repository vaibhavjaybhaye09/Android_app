from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Q
from .models import (
    PhotographerProfile, Post, Comment, Notification,
    Portfolio, Category, Story
)
from .serializers import (
    PhotographerProfileSerializer, PostSerializer, CommentSerializer,
    NotificationSerializer, PortfolioSerializer, CategorySerializer,
    StorySerializer, ConversationSerializer, MessageSerializer
)
from accounts.permissions import IsPhotographer, IsVerified


class PhotographerProfileViewSet(viewsets.ModelViewSet):
    queryset = PhotographerProfile.objects.all()
    serializer_class = PhotographerProfileSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return PhotographerProfile.objects.all()
        return PhotographerProfile.objects.filter(user=user)
    
    @action(detail=True, methods=['post'])
    def follow(self, request, pk=None):
        profile = self.get_object()
        user = request.user
        
        if profile.user == user:
            return Response({
                "error": "You cannot follow yourself"
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if user in profile.followers.all():
            profile.followers.remove(user)
            return Response({
                "message": "Unfollowed successfully",
                "followers_count": profile.followers.count()
            }, status=status.HTTP_200_OK)
        else:
            profile.followers.add(user)
            
            # Create notification
            Notification.objects.create(
                user=profile.user,
                notification_type='follow',
                from_user=user
            )
            
            return Response({
                "message": "Followed successfully",
                "followers_count": profile.followers.count()
            }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        profile = get_object_or_404(PhotographerProfile, user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)


class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        queryset = Post.objects.filter(is_archived=False)
        
        # Filter by photographer
        photographer_id = self.request.query_params.get('photographer')
        if photographer_id:
            queryset = queryset.filter(photographer_id=photographer_id)
        
        # Filter by following
        following_only = self.request.query_params.get('following')
        if following_only and following_only.lower() == 'true':
            following_users = self.request.user.following.all()
            queryset = queryset.filter(photographer__in=following_users)
        
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(photographer=self.request.user)
    
    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        post = self.get_object()
        user = request.user
        
        if user in post.likes.all():
            post.likes.remove(user)
            liked = False
        else:
            post.likes.add(user)
            liked = True
            
            # Create notification (don't notify for own post)
            if post.photographer != user:
                Notification.objects.create(
                    user=post.photographer,
                    notification_type='like',
                    from_user=user,
                    post=post
                )
        
        return Response({
            "liked": liked,
            "likes_count": post.likes.count()
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def archive(self, request, pk=None):
        post = self.get_object()
        
        if post.photographer != request.user:
            return Response({
                "error": "You can only archive your own posts"
            }, status=status.HTTP_403_FORBIDDEN)
        
        post.is_archived = True
        post.save()
        
        return Response({
            "message": "Post archived successfully"
        }, status=status.HTTP_200_OK)


class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        post_id = self.request.query_params.get('post')
        if post_id:
            return Comment.objects.filter(post_id=post_id)
        return Comment.objects.all()
    
    def perform_create(self, serializer):
        post_id = self.request.data.get('post_id')
        post = get_object_or_404(Post, id=post_id)
        comment = serializer.save(user=self.request.user, post=post)
        
        # Create notification
        if post.photographer != self.request.user:
            Notification.objects.create(
                user=post.photographer,
                notification_type='comment',
                from_user=self.request.user,
                post=post
            )
        
        return comment


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        self.get_queryset().update(is_read=True)
        return Response({
            "message": "All notifications marked as read"
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({
            "message": "Notification marked as read"
        }, status=status.HTTP_200_OK)


class PortfolioViewSet(viewsets.ModelViewSet):
    queryset = Portfolio.objects.all()
    serializer_class = PortfolioSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        if self.request.user.role == 'admin':
            return Portfolio.objects.all()
        
        photographer_id = self.request.query_params.get('photographer')
        if photographer_id:
            return Portfolio.objects.filter(photographer_id=photographer_id)
        
        if self.request.user.role == 'photographer':
            return Portfolio.objects.filter(photographer=self.request.user)
        
        return Portfolio.objects.filter(is_featured=True)
    
    def perform_create(self, serializer):
        if self.request.user.role != 'photographer':
            raise permissions.PermissionDenied("Only photographers can create portfolio items")
        serializer.save(photographer=self.request.user)


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_permissions(self):
        if self.action in ['create', 'update', 'delete']:
            return [permissions.IsAdminUser()]
        return [permissions.IsAuthenticated()]


class StoryViewSet(viewsets.ModelViewSet):
    queryset = Story.objects.all()
    serializer_class = StorySerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        # Only show active stories from followed photographers
        user = self.request.user
        following_users = user.following.all()
        return Story.objects.filter(
            photographer__in=following_users,
            expires_at__gt=timezone.now()
        )
    
    def perform_create(self, serializer):
        if self.request.user.role != 'photographer':
            raise permissions.PermissionDenied("Only photographers can create stories")
        serializer.save(photographer=self.request.user)


class ConversationViewSet(viewsets.ModelViewSet):
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        return Conversation.objects.filter(participants=self.request.user)
    
    def create(self, request):
        participant_id = request.data.get('participant_id')
        participant = get_object_or_404(User, id=participant_id)
        
        # Check if conversation already exists
        conversation = Conversation.objects.filter(
            participants=request.user
        ).filter(participants=participant).first()
        
        if not conversation:
            conversation = Conversation.objects.create()
            conversation.participants.add(request.user, participant)
        
        serializer = self.get_serializer(conversation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class MessageViewSet(viewsets.ModelViewSet):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        conversation_id = self.request.query_params.get('conversation')
        if conversation_id:
            return Message.objects.filter(conversation_id=conversation_id)
        return Message.objects.filter(sender=self.request.user)
    
    def perform_create(self, serializer):
        conversation_id = self.request.data.get('conversation')
        conversation = get_object_or_404(Conversation, id=conversation_id)
        
        # Check if user is participant
        if self.request.user not in conversation.participants.all():
            raise permissions.PermissionDenied("You are not a participant in this conversation")
        
        message = serializer.save(sender=self.request.user, conversation=conversation)
        
        # Create notification for other participants
        for participant in conversation.participants.all():
            if participant != self.request.user:
                Notification.objects.create(
                    user=participant,
                    notification_type='message',
                    from_user=self.request.user
                )
        
        return message