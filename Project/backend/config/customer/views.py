from django.shortcuts import render

# Create your views here.
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import CustomerProfile
from .serializers import CustomerProfileSerializer, FavoritePhotographerSerializer
from accounts.permissions import IsVerified
from photographers.models import PhotographerProfile, Notification


class CustomerProfileViewSet(viewsets.ModelViewSet):
    queryset = CustomerProfile.objects.all()
    serializer_class = CustomerProfileSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return CustomerProfile.objects.all()
        return CustomerProfile.objects.filter(user=user)
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        profile, created = CustomerProfile.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['post'])
    def add_favorite(self, request):
        serializer = FavoritePhotographerSerializer(data=request.data)
        
        if serializer.is_valid():
            photographer_id = serializer.validated_data['photographer_id']
            photographer = get_object_or_404(User, id=photographer_id, role='photographer')
            
            profile, created = CustomerProfile.objects.get_or_create(user=request.user)
            
            if photographer in profile.favorite_photographers.all():
                profile.favorite_photographers.remove(photographer)
                message = "Removed from favorites"
            else:
                profile.favorite_photographers.add(photographer)
                message = "Added to favorites"
                
                # Create notification for photographer
                Notification.objects.create(
                    user=photographer,
                    notification_type='follow',
                    from_user=request.user
                )
            
            return Response({
                "message": message,
                "favorites_count": profile.favorite_photographers.count()
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def favorites(self, request):
        profile, created = CustomerProfile.objects.get_or_create(user=request.user)
        favorites = profile.favorite_photographers.all()
        
        from photographers.serializers import PhotographerProfileSerializer
        photographers = PhotographerProfile.objects.filter(user__in=favorites)
        serializer = PhotographerProfileSerializer(photographers, many=True)
        
        return Response(serializer.data, status=status.HTTP_200_OK)