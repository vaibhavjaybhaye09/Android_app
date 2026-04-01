import random

def generate_otp():
    """Generates a 6-digit OTP."""
    return str(random.randint(100000, 999999))