from rest_framework import serializers
from django.conf import settings
from .models import CustomerProfile
from accounts.serializers import UserSerializer
from photographers.serializers import PhotographerProfileSerializer

class CustomerProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True, required=False)
    favorite_photographers_details = PhotographerProfileSerializer(
        source='favorite_photographers', 
        many=True, 
        read_only=True
    )
    
    class Meta:
        model = CustomerProfile
        fields = (
            'id', 'user', 'user_id', 'phone_number', 'saved_addresses',
            'favorite_photographers', 'favorite_photographers_details', 'created_at'
        )
        read_only_fields = ('id', 'created_at')
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['user'] = request.user
        elif validated_data.get('user_id'):
            validated_data['user'] = settings.AUTH_USER_MODEL.objects.get(
                id=validated_data.pop('user_id')
            )
        return super().create(validated_data)

class FavoritePhotographerSerializer(serializers.Serializer):
    photographer_id = serializers.IntegerField(required=True)
    
    def validate_photographer_id(self, value):
        try:
            photographer = settings.AUTH_USER_MODEL.objects.get(id=value, role='photographer')
        except settings.AUTH_USER_MODEL.DoesNotExist:
            raise serializers.ValidationError("Photographer not found.")
        return value