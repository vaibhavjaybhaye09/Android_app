# PhotoHub App - Quick Start Guide

## Prerequisites
- Python 3.9+ (Backend)
- Flutter 3.10+ (Frontend)
- Git
- Virtual Environment (recommended)

## Backend Setup

### 1. Navigate to Backend Directory
```bash
cd Project/backend/config
```

### 2. Create Virtual Environment
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables
Create/update `.env` file:
```
DEBUG=True
SECRET_KEY=django-insecure-6*&d+=s(*$3hrr)ze^=cql2l!5fs6%99z89yyl(o7bhnp2rm*e
ALLOWED_HOSTS=127.0.0.1,localhost,192.168.1.6
EMAIL_HOST_USER=vjwings9@gmail.com
EMAIL_HOST_PASSWORD=rpolkmtwhyhpeuly
```

### 5. Apply Migrations
```bash
python manage.py migrate
```

### 6. Create Superuser (Optional)
```bash
python manage.py createsuperuser
```

### 7. Run Backend Server
```bash
python manage.py runserver 0.0.0.0:8000
```

**Backend should be accessible at**: `http://192.168.1.6:8000`

## Frontend Setup

### 1. Navigate to Frontend Directory
```bash
cd Project/frontend
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Generate Retrofit Code (if needed)
```bash
flutter pub run build_runner build
```

### 4. Run on Device/Emulator

#### Android
```bash
flutter run
```

#### iOS
```bash
flutter run -d iphone
```

#### Web
```bash
flutter run -d chrome
```

#### Desktop (Windows)
```bash
flutter run -d windows
```

## Testing the Application

### Test Account Flow
1. **Register**
   - Email: `test@example.com`
   - Password: `Test@123456`
   - Verify OTP: Check spam folder

2. **Login**
   - Use same credentials
   - App should navigate to home screen

3. **Role Selection**
   - Choose "Photographer" or "Customer"
   - Setup profile with photo

### Test Features

#### For Photographers
- [ ] Upload portfolio items
- [ ] Create posts with images
- [ ] View followers
- [ ] Check bookings
- [ ] Update profile
- [ ] View analytics

#### For Customers
- [ ] Browse photographers
- [ ] View nearby photographers
- [ ] Book photographer
- [ ] View booking history
- [ ] Chat with photographers

### API Testing with Postman

#### 1. Register User
```
POST http://192.168.1.6:8000/api/auth/register/
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "Test@123456"
}
```

#### 2. Verify OTP
```
POST http://192.168.1.6:8000/api/auth/verify-otp/
Content-Type: application/json

{
  "email": "test@example.com",
  "otp": "123456"  # Check email for actual OTP
}
```

#### 3. Login
```
POST http://192.168.1.6:8000/api/auth/login/
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "Test@123456"
}
```

Response includes:
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "test@example.com",
    "role": "unassigned",
    "is_verified": true
  }
}
```

#### 4. Get Photographers (with Token)
```
GET http://192.168.1.6:8000/api/profiles/
Authorization: Bearer <access_token>
```

## Troubleshooting

### Backend Issues

#### ModuleNotFoundError
```bash
pip install -r requirements.txt
```

#### Port Already in Use
```bash
# Change port
python manage.py runserver 0.0.0.0:8080
```

#### Database Issues
```bash
# Reset database
rm db.sqlite3
python manage.py migrate
```

### Frontend Issues

#### Dependencies Not Found
```bash
flutter clean
flutter pub get
```

#### API Connection Failed
1. Check backend is running: `http://192.168.1.6:8000/api/profiles/`
2. Verify IP address in `core/constants/api_constants.dart`
3. Check firewall allows port 8000

#### Build Issues
```bash
flutter clean
flutter pub get
flutter run
```

## Important Endpoints

### Authentication
- `POST /api/auth/register/` - Register new user
- `POST /api/auth/verify-otp/` - Verify email OTP
- `POST /api/auth/login/` - Login user
- `POST /api/auth/logout/` - Logout (requires auth)
- `POST /api/auth/forgot-password/` - Request password reset OTP
- `POST /api/auth/reset-password/` - Reset password with OTP
- `POST /api/token/refresh/` - Refresh access token

### Photographers
- `GET /api/profiles/` - List all photographers
- `GET /api/profiles/<id>/` - Get photographer details
- `POST /api/profiles/<id>/follow/` - Follow/unfollow photographer
- `GET /api/posts/` - List posts
- `POST /api/posts/` - Create post (photographers only)
- `GET /api/posts/nearby_feed/` - Get nearby photographers' posts

### Bookings
- `GET /api/bookings/` - List user bookings
- `POST /api/bookings/` - Create new booking
- `PATCH /api/bookings/<id>/update_status/` - Update booking status
- `GET /api/bookings/my_bookings/` - Get user's bookings
- `GET /api/bookings/pending/` - Get pending bookings

### Profile
- `GET /api/auth/profile/me/` - Get logged-in user profile
- `PATCH /api/auth/profile/me/` - Update profile
- `POST /api/auth/change-password/` - Change password

## Performance Tips

### Backend
- Use pagination: Add `?page=2` to list endpoints
- Filter results: `?search=photographer_name`
- Use specific fields in requests

### Frontend
- Enable hot reload for faster development: `r` key in terminal
- Use `flutter run --profile` for performance testing
- Build release app: `flutter build apk --release`

## Deployment

### Backend (Production)
```bash
# 1. Update settings.py
DEBUG = False
ALLOWED_HOSTS = ['yourdomain.com']
CORS_ALLOWED_ORIGINS = ['https://yourdomain.com']

# 2. Collect static files
python manage.py collectstatic --noinput

# 3. Use production server (e.g., Gunicorn)
gunicorn config.wsgi:application --bind 0.0.0.0:8000

# 4. Use proper database (PostgreSQL)
# Update DATABASE settings in settings.py
```

### Frontend (Release Build)
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## Support

For issues or questions:
1. Check FIXES_APPLIED.md for detailed changes
2. Review error logs in terminal
3. Check Django admin at `http://192.168.1.6:8000/admin/`
4. Verify database migrations are applied

## Next Steps

After everything is working:
1. **Add Unit Tests**: Implement testing suite
2. **Setup CI/CD**: GitHub Actions for automated testing
3. **Configure Production**: Prepare for deployment
4. **Performance Optimization**: Implement caching and CDN
5. **Monitoring**: Setup error tracking with Sentry

---
**Last Updated**: May 29, 2026
**App Status**: Ready for Development & Testing
