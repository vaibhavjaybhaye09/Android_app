from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import User, UserProfile, Skill, Service, PortfolioItem, EmailOTP

User = get_user_model()

class SkillSerializer(serializers.ModelSerializer):
    class Meta:
        model = Skill
        fields = ('id', 'name')

class UserProfileSerializer(serializers.ModelSerializer):
    skills = SkillSerializer(many=True, read_only=True)
    skill_ids = serializers.ListField(
        child=serializers.IntegerField(), write_only=True, required=False
    )
    email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = UserProfile
        fields = ('id', 'email', 'display_name', 'profile_picture', 'bio', 'location', 'skills', 'skill_ids')

    def update(self, instance, validated_data):
        skill_ids = validated_data.pop('skill_ids', None)
        if skill_ids is not None:
            instance.skills.set(Skill.objects.filter(id__in=skill_ids))
        return super().update(instance, validated_data)

class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = '__all__'
        read_only_fields = ('user',)

class PortfolioItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = PortfolioItem
        fields = '__all__'
        read_only_fields = ('user',)

class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)
    
    class Meta:
        model = User
        fields = ('id', 'email', 'profile')

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('email', 'password')

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password']
        )
        UserProfile.objects.create(user=user)
        return user

class EmailOTPSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailOTP
        fields = '__all__'

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is not correct")
        return value

class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        if not User.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email does not exist")
        return value

class ResetPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField()
    new_password = serializers.CharField()

    def validate(self, data):
        try:
            user = User.objects.get(email=data['email'])
            otp_obj = EmailOTP.objects.filter(user=user, otp=data['otp'], is_verified=False).last()
            if not otp_obj:
                raise serializers.ValidationError("Invalid OTP")
            data['user'] = user
            data['otp_obj'] = otp_obj
            return data
        except User.DoesNotExist:
            raise serializers.ValidationError("User not found")
