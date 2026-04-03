from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PhotographerProfileViewSet, PostViewSet, CommentViewSet,
    NotificationViewSet, PortfolioViewSet, CategoryViewSet,
    StoryViewSet, ConversationViewSet, MessageViewSet
)

router = DefaultRouter()
router.register(r'profiles', PhotographerProfileViewSet, basename='profile')
router.register(r'posts', PostViewSet, basename='post')
router.register(r'comments', CommentViewSet, basename='comment')
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'portfolio', PortfolioViewSet, basename='portfolio')
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'stories', StoryViewSet, basename='story')
router.register(r'conversations', ConversationViewSet, basename='conversation')
router.register(r'messages', MessageViewSet, basename='message')

urlpatterns = [
    path('', include(router.urls)),
]