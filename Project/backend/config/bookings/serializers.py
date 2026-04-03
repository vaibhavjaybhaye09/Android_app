from rest_framework import serializers
from django.conf import settings
from .models import Booking
from accounts.serializers import UserSerializer

class BookingSerializer(serializers.ModelSerializer):
    photographer = UserSerializer(read_only=True)
    photographer_id = serializers.IntegerField(write_only=True, required=False)
    customer = UserSerializer(read_only=True)
    customer_id = serializers.IntegerField(write_only=True, required=False)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Booking
        fields = (
            'id', 'photographer', 'photographer_id', 'customer', 'customer_id',
            'event_date', 'event_type', 'location', 'status', 'status_display',
            'created_at'
        )
        read_only_fields = ('id', 'created_at')
    
    def validate_event_date(self, value):
        from django.utils import timezone
        if value < timezone.now():
            raise serializers.ValidationError("Event date cannot be in the past.")
        return value
    
    def create(self, validated_data):
        request = self.context.get('request')
        
        # If photographer_id is provided, use it, otherwise use the current user if they're a photographer
        if validated_data.get('photographer_id'):
            validated_data['photographer'] = settings.AUTH_USER_MODEL.objects.get(
                id=validated_data.pop('photographer_id')
            )
        elif request and request.user.role == 'photographer':
            validated_data['photographer'] = request.user
        
        # Set customer
        if validated_data.get('customer_id'):
            validated_data['customer'] = settings.AUTH_USER_MODEL.objects.get(
                id=validated_data.pop('customer_id')
            )
        elif request and request.user.is_authenticated:
            validated_data['customer'] = request.user
        
        return super().create(validated_data)

class BookingUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = ('status', 'event_date', 'event_type', 'location')
    
    def validate(self, data):
        # Only photographer can update booking status
        request = self.context.get('request')
        if 'status' in data and request and request.user.role != 'photographer':
            raise serializers.ValidationError("Only photographers can update booking status.")
        return data