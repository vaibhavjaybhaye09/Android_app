# PhotoHub App - Testing & Validation Checklist

## Pre-Launch Validation Checklist

Use this checklist to verify all fixes are working correctly before deploying the app.

### ✅ Setup & Installation

- [ ] Backend virtual environment created
- [ ] Backend dependencies installed (`pip install -r requirements.txt`)
- [ ] Frontend dependencies resolved (`flutter pub get`)
- [ ] `.env` file configured with correct credentials
- [ ] Database migrations applied (`python manage.py migrate`)
- [ ] Backend server starts without errors
- [ ] Frontend builds without errors

---

## Backend Testing

### 1. OTP Expiry Bug Fix ✅

#### Test Case 1: OTP Verification Within Timeout
```
STEPS:
1. Register with email: test1@example.com
2. Get OTP from backend logs or email
3. Verify OTP immediately (within 10 minutes)

EXPECTED RESULT:
✓ OTP verification succeeds
✓ User is marked as verified
✓ Redirect to login

VERIFICATION:
python manage.py shell
>>> from accounts.models import EmailOTP
>>> EmailOTP.objects.filter(user__email='test1@example.com').last()
```

#### Test Case 2: OTP Expiry After Timeout
```
STEPS:
1. Register with email: test2@example.com
2. Calculate OTP creation time
3. Wait 601 seconds (10 minutes + 1 second) OR modify created_at in DB
4. Try to verify OTP

EXPECTED RESULT:
✓ Get error: "OTP has expired"
✗ User is not verified
✗ Cannot proceed to login

VERIFICATION:
Check terminal logs for "OTP has expired" message
```

**Status**: ✅ Fixed using `.total_seconds()`

---

### 2. CORS Security Fix ✅

#### Test Case: Restricted CORS
```
STEPS:
1. Start backend: python manage.py runserver 0.0.0.0:8000
2. From browser console on http://localhost:3000, try:
   fetch('http://192.168.1.6:8000/api/profiles/')
3. Check browser Network tab

EXPECTED RESULT:
✓ Request succeeds (development domain)
✓ Proper CORS headers in response

VERIFICATION:
Check response headers:
- Access-Control-Allow-Origin: http://192.168.1.6:8000
- Access-Control-Allow-Methods: GET, POST, etc.
```

**Status**: ✅ Updated CORS_ALLOWED_ORIGINS in settings.py

---

### 3. CSRF Protection Fix ✅

#### Test Case: Token-Based Auth CSRF
```
STEPS:
1. Login via API: POST /api/auth/login/
2. Get JWT access token
3. Use token for subsequent requests with Authorization header
4. Make POST/PATCH/DELETE requests

EXPECTED RESULT:
✓ All requests succeed
✓ No CSRF token required (JWT auth bypasses CSRF)
✗ No CSRF_EXEMPT bypass

VERIFICATION:
Check that decorators are removed:
grep "@method_decorator(csrf_exempt" accounts/views.py
(Should return empty)
```

**Status**: ✅ Removed csrf_exempt decorators

---

### 4. Missing Import Fix ✅

#### Test Case: Booking Creation
```
STEPS:
1. Login as customer: test_customer@example.com
2. Create booking via API: POST /api/bookings/
3. Check booking creation succeeds

EXPECTED RESULT:
✓ Booking created successfully
✓ No "NameError: name 'User' is not defined"

VERIFICATION:
Check Django logs for no import errors
```

**Status**: ✅ Added User import to bookings/views.py

---

### 5. Pagination Implementation ✅

#### Test Case: List Endpoints Pagination
```
STEPS:
1. GET /api/profiles/
2. GET /api/profiles/?page=2
3. GET /api/bookings/?page=1

EXPECTED RESULT FOR EACH:
✓ Response includes pagination data:
  {
    "count": 15,
    "next": "http://..../api/profiles/?page=2",
    "previous": null,
    "results": [...]
  }
✓ Default 10 items per page
✓ Page number parameter works

VERIFICATION:
curl -H "Authorization: Bearer <token>" \
  http://192.168.1.6:8000/api/profiles/
```

**Status**: ✅ Added DEFAULT_PAGINATION_CLASS and PAGE_SIZE

---

## Frontend Testing

### 1. API Error Handling ✅

#### Test Case 1: Network Timeout
```
STEPS:
1. Start app
2. Turn off internet/API server
3. Try to load photographers

EXPECTED RESULT:
✓ Show user-friendly error: "Connection timeout. Please check your internet connection."
✗ No technical exception message
✗ App doesn't crash

VERIFICATION:
Check SnackBar message in app
```

#### Test Case 2: 401 Unauthorized
```
STEPS:
1. Get expired token (modify token expiry in code)
2. Try API call

EXPECTED RESULT:
✓ Token refresh triggered automatically
✓ Request retried with new token
✓ No UI error shown if refresh succeeds

VERIFICATION:
Check logs in VS Code terminal
```

#### Test Case 3: 404 Not Found
```
STEPS:
1. Try to access non-existent photographer: GET /api/profiles/99999/

EXPECTED RESULT:
✓ Show error: "Resource not found."
✗ No generic exception

VERIFICATION:
Check error message in UI
```

**Status**: ✅ Implemented ApiException class

---

### 2. Token Refresh Logic ✅

#### Test Case: Auto Token Refresh
```
STEPS:
1. Login successfully, get tokens
2. Wait for access token to expire (or mock expiry)
3. Make API call

EXPECTED RESULT:
✓ DioClient detects 401
✓ Automatically sends refresh token
✓ Gets new access token
✓ Retries original request with new token
✓ User doesn't notice anything

VERIFICATION:
Check Dio logs showing retry with new token
Monitor flutter pub logs:
flutter run --verbose | grep "token\|401"
```

**Status**: ✅ Implemented in DioClient with Completer pattern

---

### 3. User-Friendly Error Messages ✅

#### Test Case: Error Message Display
```
STEPS:
1. Trigger each error type:
   a. Internet down: Connection timeout
   b. Server down: Connection refused  
   c. Wrong credentials: 401 Unauthorized
   d. Server error: 500 Server Error
   e. Not found: 404 Not Found

EXPECTED RESULT FOR EACH:
✓ Clear, user-friendly message
✓ Actionable guidance (e.g., "check internet")
✗ Technical exception details
✗ Status codes exposed

VERIFICATION:
App shows messages like:
- "Connection timeout. Please check your internet connection."
- "Unauthorized. Please log in again."
- "Server error. Please try again later."
```

**Status**: ✅ _getErrorMessage() method implemented

---

## Integration Testing

### 1. Complete Login Flow

#### Test Case: Register → Verify → Login
```
SEQUENCE:
1. App starts (splash screen)
2. Navigate to Register
3. Enter email: integration_test@example.com
4. Enter password: Test@123456
5. Submit registration
   ✓ Get response: "Registration successful. Please verify your email."
   ✓ OTP sent to email
6. Check email for OTP (check logs if using test email)
7. Navigate to verify OTP
8. Enter OTP
   ✓ Get response: "Email verified successfully"
   ✓ Auto-navigate to login
9. Enter credentials again
   ✓ Get response with tokens
10. Navigate to role selection
11. Select "Photographer"
    ✓ Create photographer profile
    ✓ Navigate to home screen
12. Home screen shows:
    ✓ Photographer list
    ✓ Bottom navigation (Explore, Bookings, Chat, Profile)

EXPECTED ERRORS:
✗ No exceptions in logs
✗ No network errors
✗ All network requests successful
```

**Status**: ✅ To be verified

---

### 2. Photographer Browse & Booking

#### Test Case: Browse Photographers & Make Booking
```
SEQUENCE (Customer Account):
1. Login as customer
2. Go to "Explore" tab
   ✓ Load photographer list with pagination
3. Click photographer card
   ✓ Load photographer details
4. View portfolio/posts/services
5. Click "Book Now"
   ✓ Booking modal opens
6. Select date and enter notes
7. Submit booking
   ✓ Booking created
   ✓ Status shows "pending"
8. Go to "Bookings" tab
   ✓ New booking visible
9. Check photographer receives notification

EXPECTED RESPONSES:
✓ All API calls succeed
✓ Images load properly
✓ No UI glitches
```

**Status**: ✅ To be verified

---

### 3. Real-Time Features

#### Test Case: Chat Messaging
```
SEQUENCE (Two Accounts):
Account A (Photographer):
1. Login as photographer
2. Go to "Chat" tab
3. Wait for messages from Customer

Account B (Customer):
1. Login as customer
2. Find photographer's profile
3. Click "Message"
4. Send message: "Hi! Interested in booking"
5. Check A receives message

EXPECTED:
✓ Message appears in B's sent list immediately
✓ Message appears in A's received list (HTTP polling or WebSocket)
✓ Both see conversation in chat list
```

**Status**: ✅ To be verified (needs WebSocket upgrade)

---

## Performance Testing

### 1. Load Testing

#### Backend Load Test
```bash
# Install artillery
npm install -g artillery

# Create test.yml
target: http://192.168.1.6:8000
phases:
  - duration: 60
    arrivalRate: 10  # 10 requests/second

# Run test
artillery run test.yml

EXPECTED RESULTS:
✓ 95th percentile response time < 1000ms
✓ Error rate < 1%
✓ Throughput > 50 req/s
```

#### Frontend Performance
```bash
# Run performance profile
flutter run --profile

# Check metrics
✓ Startup time < 3 seconds
✓ Navigation transition < 300ms
✓ Image loading < 2 seconds
✓ Memory usage < 200MB
```

**Status**: ✅ To be tested

---

### 2. Memory Leak Testing

#### Frontend Memory Test
```bash
STEPS:
1. Open DevTools (flutter run -> press 'd')
2. Go to Memory tab
3. Navigate through app:
   - Home → Photographer Details → Home
   - Open Chat → Close → Open Chat
   - Upload Image → Cancel → Try again
4. Take memory snapshots at each step
5. Trigger garbage collection

EXPECTED:
✓ Memory returns to baseline after navigation
✗ Continuous memory growth (leak)
✗ Memory jumps > 50MB per navigation
```

**Status**: ✅ To be tested

---

## Security Testing

### 1. Authentication Security

#### Test Case: Token Tampering
```
STEPS:
1. Get valid token from login
2. Modify token (change payload)
3. Try API call with modified token

EXPECTED:
✗ Request fails with 401
✗ Token accepted
```

#### Test Case: Token Extraction
```
STEPS:
1. Check flutter_secure_storage usage
2. Verify tokens not in SharedPreferences
3. Verify tokens not in logs

EXPECTED:
✓ Tokens stored in secure storage
✗ Tokens visible in logs
✗ Tokens in regular SharedPreferences
```

**Status**: ✅ Using flutter_secure_storage

---

### 2. CORS Security

#### Test Case: Cross-Origin Requests
```
STEPS:
1. From attacker domain (non-whitelisted)
2. Try to make request to API

EXPECTED:
✗ Request succeeds from attacker domain
✓ Browser blocks request (CORS error)
```

**Status**: ✅ Restricted CORS origins

---

### 3. Input Validation

#### Test Case: SQL Injection
```
STEPS:
1. Registration email: admin' OR '1'='1
2. Try login with SQL payload

EXPECTED:
✗ Request succeeds (SQL executed)
✓ Input treated as literal string
✓ No SQL injection possible
```

**Status**: ✅ Django ORM prevents SQL injection

---

## Browser Compatibility Testing (Web)

If deploying web version:

- [ ] Chrome/Chromium latest
- [ ] Firefox latest
- [ ] Safari latest
- [ ] Edge latest
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

```bash
flutter run -d chrome
flutter run -d edge
```

---

## Device Testing (Mobile)

### Android Devices
- [ ] Android 7.0+ (API 24+)
- [ ] Various screen sizes (4.5", 5.5", 6.5")
- [ ] Different RAM configurations (2GB, 4GB, 6GB+)

### iOS Devices
- [ ] iOS 12.0+
- [ ] iPhone (various sizes)
- [ ] iPad

```bash
# Android
flutter run

# iOS
flutter run -d iphone

# List devices
flutter devices
```

---

## Database Testing

### Test Case: Data Consistency
```sql
-- Check user creation
SELECT COUNT(*) FROM accounts_user WHERE email = 'test@example.com';

-- Check OTP creation
SELECT * FROM accounts_emailotp WHERE user_id = 1;

-- Check booking creation
SELECT * FROM bookings_booking WHERE customer_id = 1;

-- Check cascading delete
DELETE FROM accounts_user WHERE id = 1;
SELECT COUNT(*) FROM accounts_userprofile WHERE user_id = 1;  -- Should be 0
```

**Status**: ✅ To be verified

---

## API Documentation Testing

### Test Case: OpenAPI Documentation
```bash
STEPS:
1. Access API docs: http://192.168.1.6:8000/api/schema/
2. Verify all endpoints listed:
   - /api/auth/register/
   - /api/auth/login/
   - /api/auth/verify-otp/
   - /api/profiles/
   - /api/bookings/
   - etc.
3. Test endpoint from documentation UI
4. Verify request/response format

EXPECTED:
✓ All endpoints documented
✓ Parameters clearly defined
✓ Example requests work
```

**Status**: ✅ drf-spectacular installed

---

## Final Validation Checklist

- [ ] All bugs fixed without introducing new ones
- [ ] No performance regression
- [ ] Security improvements verified
- [ ] Error messages user-friendly
- [ ] Token refresh working smoothly
- [ ] Pagination functional
- [ ] CORS restricted properly
- [ ] Code follows best practices
- [ ] No debug code in production
- [ ] Logging appropriate (not verbose in prod)
- [ ] Documentation accurate and complete
- [ ] Dependencies up to date and secure
- [ ] Database schema sound
- [ ] Frontend UI responsive and smooth
- [ ] Network failures handled gracefully

---

## Sign-Off

**Testing Completed By**: ____________________
**Date**: ____________________
**Status**: ✅ READY FOR PRODUCTION / ⚠️ NEEDS FIXES / ❌ BLOCKING ISSUES

**Issues Found** (if any):
1. ____________________
2. ____________________
3. ____________________

**Notes**:
____________________

---

**Last Updated**: May 29, 2026
**App Version**: 1.0.0
**Status**: Ready for UAT & Deployment
