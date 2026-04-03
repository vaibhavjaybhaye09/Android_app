from rest_framework import permissions

class IsVerified(permissions.BasePermission):
    """Allow access only to verified users"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.is_verified


class IsPhotographer(permissions.BasePermission):
    """Allow access only to photographers"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.role == 'photographer' and request.user.is_verified


class IsCustomer(permissions.BasePermission):
    """Allow access only to customers"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.role == 'customer' and request.user.is_verified


class IsAdmin(permissions.BasePermission):
    """Allow access only to admins"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.role == 'admin' and request.user.is_verified


class IsOwnerOrReadOnly(permissions.BasePermission):
    """Allow edit only to owner of object"""
    
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Check if obj has user attribute
        if hasattr(obj, 'user'):
            return obj.user == request.user
        elif hasattr(obj, 'photographer'):
            return obj.photographer == request.user
        elif hasattr(obj, 'customer'):
            return obj.customer == request.user
        elif hasattr(obj, 'sender'):
            return obj.sender == request.user
        
        return False