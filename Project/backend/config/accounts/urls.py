from django.urls import path, include
from django.views.decorators.csrf import csrf_exempt
from rest_framework.routers import DefaultRouter
from .views import (
    RegisterView, VerifyOTPView, LoginView, ResendOTPView,
    ChangePasswordView, ForgotPasswordView, ResetPasswordView,
    LogoutView, UserProfileViewSet, SkillViewSet,
    ServiceViewSet, PortfolioItemViewSet
)

router = DefaultRouter()
router.register(r'profile', UserProfileViewSet, basename='userprofile')
router.register(r'skills', SkillViewSet, basename='skill')
router.register(r'services', ServiceViewSet, basename='service')
router.register(r'portfolio', PortfolioItemViewSet, basename='portfolio')

urlpatterns = [
    path('', include(router.urls)),
    path('register/', csrf_exempt(RegisterView.as_view()), name='register'),
    path('verify-otp/', csrf_exempt(VerifyOTPView.as_view()), name='verify-otp'),
    path('resend-otp/', csrf_exempt(ResendOTPView.as_view()), name='resend-otp'),
    path('login/', csrf_exempt(LoginView.as_view()), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path(
        'forgot-password/',
        csrf_exempt(ForgotPasswordView.as_view()),
        name='forgot-password',
    ),
    path(
        'reset-password/',
        csrf_exempt(ResetPasswordView.as_view()),
        name='reset-password',
    ),
]
