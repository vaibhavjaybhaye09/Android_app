from rest_framework.views import APIView
from rest_framework.response import Response
from django.core.mail import send_mail
from .models import User, EmailOTP
from .serializers import RegisterSerializer
from .utils import generate_otp
from rest_framework_simplejwt.tokens import RefreshToken


class RegisterView(APIView):

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            otp = generate_otp()
            EmailOTP.objects.create(
                user=user,
                otp=otp
            )

            send_mail(
                'Your Verification OTP',
                f'Your OTP is {otp}',
                'noreply@app.com',
                [user.email],
                fail_silently=False
            )

            return Response({
                "message": "OTP sent to email"
            })
        return Response(serializer.errors)
    
class VerifyOTPView(APIView):

    def post(self, request):

        email = request.data.get("email")
        otp = request.data.get("otp")
        user = User.objects.get(email=email)

        otp_obj = EmailOTP.objects.filter(
            user=user,
            otp=otp,
            is_verified=False
        ).last()

        if not otp_obj:
            return Response({"error": "Invalid OTP"})

        otp_obj.is_verified = True
        otp_obj.save()

        user.is_verified = True
        user.save()

        return Response({
            "message": "Email verified successfully"
        })
    
    
class LoginView(APIView):

    def post(self, request):

        email = request.data.get("email")
        password = request.data.get("password")
        user = User.objects.filter(email=email).first()

        if not user:
            return Response({"error": "User not found"})

        if not user.check_password(password):
            return Response({"error": "Invalid password"})

        if not user.is_verified:
            return Response({"error": "Email not verified"})

        refresh = RefreshToken.for_user(user)

        return Response({
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "role": user.role
        })