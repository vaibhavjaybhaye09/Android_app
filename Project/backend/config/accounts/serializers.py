from rest_framework import serializers
from django.contrib.auth import authenticate
from django.utils import timezone
from .models import User, EmailOTP


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    confirm_password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    
    class Meta:
        model = User
        fields = ('email', 'password', 'confirm_password', 'role')
    
    def validate(self, attrs):
        # Check if passwords match
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError({
                "confirm_password": "Passwords do not match."
            })
        
        # Validate password length
        if len(attrs['password']) < 8:
            raise serializers.ValidationError({
                "password": "Password must be at least 8 characters long."
            })
        
        # Validate role
        if attrs.get('role') not in ['photographer', 'customer']:
            attrs['role'] = 'customer'  # Default to customer
        
        # Check if email already exists
        if User.objects.filter(email=attrs['email']).exists():
            raise serializers.ValidationError({
                "email": "A user with this email already exists."
            })
        
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('confirm_password')
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data.get('role', 'customer')
        )
        return user


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'email', 'role', 'is_verified', 'date_joined', 'last_login')
        read_only_fields = ('id', 'is_verified', 'date_joined', 'last_login')


class EmailOTPSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailOTP
        fields = ('id', 'user', 'otp', 'created_at', 'is_verified')
        read_only_fields = ('id', 'created_at')


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True)
    confirm_password = serializers.CharField(required=True, write_only=True)
    
    def validate(self, attrs):
        # Check if new passwords match
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError({
                "confirm_password": "New passwords do not match."
            })
        
        # Validate password length
        if len(attrs['new_password']) < 8:
            raise serializers.ValidationError({
                "new_password": "Password must be at least 8 characters long."
            })
        
        return attrs
    
    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is incorrect.")
        return value


class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    
    def validate_email(self, value):
        try:
            user = User.objects.get(email=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("User with this email does not exist.")
        return value


class ResetPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    otp = serializers.CharField(max_length=6, required=True)
    new_password = serializers.CharField(required=True, write_only=True)
    confirm_password = serializers.CharField(required=True, write_only=True)
    
    def validate(self, attrs):
        # Check if new passwords match
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError({
                "confirm_password": "Passwords do not match."
            })
        
        # Validate password length
        if len(attrs['new_password']) < 8:
            raise serializers.ValidationError({
                "new_password": "Password must be at least 8 characters long."
            })
        
        try:
            user = User.objects.get(email=attrs['email'])
            otp_obj = EmailOTP.objects.filter(
                user=user, 
                otp=attrs['otp'], 
                is_verified=False
            ).last()
            
            if not otp_obj:
                raise serializers.ValidationError("Invalid OTP.")
            
            # Check OTP expiry (10 minutes)
            from django.utils import timezone
            if (timezone.now() - otp_obj.created_at).seconds > 600:
                raise serializers.ValidationError("OTP has expired. Please request a new one.")
            
            attrs['user'] = user
            attrs['otp_obj'] = otp_obj
            
        except User.DoesNotExist:
            raise serializers.ValidationError("User with this email does not exist.")
        
        return attrs