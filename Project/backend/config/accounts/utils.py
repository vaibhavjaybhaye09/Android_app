import random
import string
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags

def generate_otp(length=6):
    """Generates a numeric OTP of specified length."""
    return ''.join(random.choices(string.digits, k=length))

def generate_random_password(length=12):
    """Generates a random password."""
    characters = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(random.choices(characters, k=length))

def send_otp_email(user_email, otp, is_password_reset=False):
    """Send OTP email to user."""
    subject = 'Password Reset OTP' if is_password_reset else 'Verify Your Email'
    
    # Simple email body
    message = f"""
    Hello,
    
    Your {'password reset' if is_password_reset else 'verification'} OTP is: {otp}
    
    This OTP will expire in 10 minutes.
    
    If you didn't request this, please ignore this email.
    
    Thank you!
    """
    
    send_mail(
        subject,
        message,
        settings.DEFAULT_FROM_EMAIL,
        [user_email],
        fail_silently=False
    )

def send_welcome_email(user_email, user_name):
    """Send welcome email after successful verification."""
    subject = 'Welcome to Our Platform!'
    message = f"""
    Hello {user_name},
    
    Welcome to our platform! Your email has been successfully verified.
    
    You can now log in and start exploring.
    
    Thank you for joining us!
    """
    
    send_mail(
        subject,
        message,
        settings.DEFAULT_FROM_EMAIL,
        [user_email],
        fail_silently=False
    )