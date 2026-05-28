from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Q
from django.utils import timezone
from .models import (
    PhotographerProfile, Post, Comment, Notification,
    Portfolio, Category, Story, Conversation, Message
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
        queryset = PhotographerProfile.objects.all()
        
        # Admin can see everything
        if self.request.user.is_staff:
            return queryset
            
        # Search by name or city
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(display_name__icontains=search) | 
                Q(city__icontains=search) |
                Q(area__icontains=search)
            )
            
        # Filter by experience
        min_exp = self.request.query_params.get('min_experience')
        if min_exp:
            queryset = queryset.filter(experience__gte=min_exp)
            
        # Filter by rating
        min_rating = self.request.query_params.get('min_rating')
        if min_rating:
            queryset = queryset.filter(rating__gte=min_rating)

        return queryset
    
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


from django.db.models import Q, Case, When, Value, IntegerField
from customer.models import CustomerProfile

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

    @action(detail=False, methods=['get'])
    def nearby_feed(self, request):
        user = request.user
        city = None
        area = None
        pincode = None

        # Try to get location from CustomerProfile
        try:
            customer_profile = CustomerProfile.objects.get(user=user)
            city = customer_profile.city
            area = customer_profile.area
            pincode = customer_profile.pincode
        except CustomerProfile.DoesNotExist:
            # Try to get location from PhotographerProfile
            try:
                photographer_profile = PhotographerProfile.objects.get(user=user)
                city = photographer_profile.city
                area = photographer_profile.area
                pincode = photographer_profile.pincode
            except PhotographerProfile.DoesNotExist:
                pass

        if not city:
            return Response({
                "error": "Profile location details (city, area, pincode) are required for nearby feed."
            }, status=status.HTTP_400_BAD_REQUEST)

        # Base queryset: Posts from photographers in the same city
        queryset = Post.objects.filter(
            is_archived=False,
            photographer__photographer_profile__city=city
        ).distinct()

        # Rank based on location proximity
        queryset = queryset.annotate(
            relevance=Case(
                # Priority 1: Exact Area and Pincode match
                When(
                    Q(photographer__photographer_profile__area=area) & 
                    Q(photographer__photographer_profile__pincode=pincode),
                    then=Value(1)
                ),
                # Priority 2: Same City (already filtered, but we can give it a lower priority weight)
                default=Value(2),
                output_field=IntegerField(),
            )
        ).order_by('relevance', '-created_at')

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
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
        if self.request.user.is_staff:
            return Portfolio.objects.all()
        
        photographer_id = self.request.query_params.get('photographer')
        if photographer_id:
            return Portfolio.objects.filter(photographer_id=photographer_id)

        # In the new single-profile system, we filter by the user directly
        return Portfolio.objects.filter(photographer=self.request.user)
    
    def perform_create(self, serializer):
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
        photographer_id = self.request.query_params.get('photographer')
        if photographer_id:
            return Story.objects.filter(
                photographer_id=photographer_id,
                expires_at__gt=timezone.now()
            )
            
        # Default: show active stories from followed photographers
        user = self.request.user
        following_users = user.following.all()
        return Story.objects.filter(
            photographer__in=following_users,
            expires_at__gt=timezone.now()
        )
    
    def perform_create(self, serializer):
        serializer.save(photographer=self.request.user)


class ConversationViewSet(viewsets.ModelViewSet):
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        return Conversation.objects.filter(participants=self.request.user)
    
    def create(self, request):
        from accounts.models import User
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
