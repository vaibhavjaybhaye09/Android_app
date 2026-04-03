from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Q
from .models import Booking
from .serializers import BookingSerializer, BookingUpdateSerializer
from accounts.permissions import IsPhotographer, IsVerified
from photographers.models import Notification


class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.all()
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated, IsVerified]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.role == 'admin':
            return Booking.objects.all()
        elif user.role == 'photographer':
            return Booking.objects.filter(photographer=user)
        else:  # customer
            return Booking.objects.filter(customer=user)
    
    def perform_create(self, serializer):
        customer = self.request.user
        
        # If customer is booking
        if customer.role == 'customer':
            booking = serializer.save(customer=customer)
            
            # Create notification for photographer
            Notification.objects.create(
                user=booking.photographer,
                notification_type='booking',
                from_user=customer
            )
            
            return booking
        
        # If photographer is creating booking for customer
        elif customer.role == 'photographer':
            customer_id = self.request.data.get('customer_id')
            if customer_id:
                customer_user = get_object_or_404(User, id=customer_id)
                booking = serializer.save(photographer=customer, customer=customer_user)
                
                # Create notification for customer
                Notification.objects.create(
                    user=customer_user,
                    notification_type='booking',
                    from_user=customer
                )
                
                return booking
        
        raise permissions.PermissionDenied("You don't have permission to create bookings")
    
    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        booking = self.get_object()
        serializer = BookingUpdateSerializer(booking, data=request.data, partial=True, context={'request': request})
        
        if serializer.is_valid():
            old_status = booking.status
            updated_booking = serializer.save()
            
            # Create notification for customer when status changes
            if old_status != updated_booking.status and updated_booking.status in ['confirmed', 'completed', 'cancelled']:
                Notification.objects.create(
                    user=updated_booking.customer,
                    notification_type='booking',
                    from_user=request.user
                )
            
            return Response({
                "message": f"Booking status updated to {updated_booking.get_status_display()}",
                "booking": serializer.data
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def my_bookings(self, request):
        """Get bookings for current user"""
        user = request.user
        
        if user.role == 'photographer':
            bookings = Booking.objects.filter(photographer=user)
        else:
            bookings = Booking.objects.filter(customer=user)
        
        serializer = self.get_serializer(bookings, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get pending bookings"""
        user = request.user
        if user.role == 'photographer':
            bookings = Booking.objects.filter(photographer=user, status='pending')
        else:
            bookings = Booking.objects.filter(customer=user, status='pending')
        
        serializer = self.get_serializer(bookings, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)