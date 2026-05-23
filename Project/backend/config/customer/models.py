from django.db import models
from django.conf import settings

class CustomerProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='customer_profile'
    )
    profile_picture = models.ImageField(upload_to='customers/', blank=True, null=True)
    full_name = models.CharField(max_length=255, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    location = models.CharField(max_length=255, blank=True, null=True)
    saved_addresses = models.JSONField(default=list, blank=True)
    city = models.CharField(max_length=100)
    area = models.CharField(max_length=100)
    pincode = models.CharField(max_length=10)   
    rating = models.FloatField(default=0)
    favorite_photographers = models.ManyToManyField(
        settings.AUTH_USER_MODEL, 
        blank=True, 
        related_name='favorited_by'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.email}'s profile"


