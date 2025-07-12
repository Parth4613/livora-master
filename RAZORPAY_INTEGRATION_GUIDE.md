# Razorpay In-App WebView Integration Guide

## Overview
This guide explains how to integrate Razorpay payment gateway into your Livora app using in-app WebView for handling payments for listing services and premium plans.

## Files Modified/Created

### 1. **Dependencies Added**
- `pubspec.yaml`: Added `webview_flutter: ^4.7.0`

### 2. **New Files Created**
- `lib/services/razorpay_inapp_service.dart`: In-app WebView payment service
- `lib/payment_success_page.dart`: Success page after payment
- `assets/animations/success.json`: Success animation
- `RAZORPAY_INTEGRATION_GUIDE.md`: This guide

### 3. **Files Modified**
- `lib/services/efficient_payment_service.dart`: Updated to use in-app WebView
- `lib/premium_plans_page.dart`: Updated to use Google Play Billing for premium plans
- `lib/widgets/list_hostel_form.dart`: Updated to use in-app WebView for listings
- `pubspec.yaml`: Added WebView dependency

## Setup Instructions

### Step 1: Get Razorpay Keys
1. Sign up at [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Create a new account or log in
3. Go to Settings → API Keys
4. Generate a new key pair
5. Copy the Key ID and Key Secret

### Step 2: Update Razorpay Keys
In `lib/services/razorpay_inapp_service.dart`, replace:
```dart
static const String _razorpayKey = 'rzp_test_YOUR_KEY_HERE'; // Test key
```
With your actual Razorpay key:
```dart
static const String _razorpayKey = 'rzp_test_1234567890abcdef'; // Your test key
```

### Step 3: Install Dependencies
Run the following command:
```bash
flutter pub get
```

## Integration Points

### 1. **Premium Plans Payment (Google Play Billing)**
**File**: `lib/premium_plans_page.dart`
- **Trigger**: User clicks "Buy Now" on premium plans
- **Flow**: 
  1. User selects a plan
  2. Google Play Billing opens (native Android)
  3. User completes payment
  4. Plan is activated and saved to user's account
  5. Success message shown

### 2. **Listing Services Payment (In-App WebView)**
**Files**: 
- `lib/widgets/list_hostel_form.dart`
- `lib/widgets/list_room_form.dart`
- `lib/widgets/list_service_form.dart`
- `lib/widgets/room_request_form.dart`

**Flow**:
1. User fills listing form
2. User selects payment plan
3. Form is submitted with `paymentStatus: 'pending'`
4. In-app WebView opens with Razorpay payment form
5. After successful payment:
   - Listing becomes visible (`visibility: true`)
   - Payment record is saved
   - Success message shown

### 3. **Payment Records**
All payments are stored in Firestore collection `payments` with structure:
```json
{
  "userId": "user_id",
  "paymentId": "razorpay_payment_id",
  "orderId": "razorpay_order_id",
  "signature": "razorpay_signature",
  "amount": 99.0,
  "currency": "INR",
  "type": "listing|premium_plan",
  "listingType": "list_hostelpg|list_room|list_service|room_request",
  "planName": "1Day|7Day|15Day|1Month|Express Hunt|Prime Seeker|Precision Pro",
  "listingId": "listing_document_id",
  "status": "success|failed",
  "createdAt": "timestamp"
}
```

## Payment Flow Details

### Premium Plans (Google Play Billing)
1. **Express Hunt** (₹29) - 7 days access
2. **Prime Seeker** (₹49) - 30 days access  
3. **Precision Pro** (₹99) - 30 days access + advanced features

### Listing Services (In-App WebView)
1. **1 Day** - Basic visibility for 1 day
2. **7 Days** - Extended visibility for 7 days
3. **15 Days** - Medium-term visibility for 15 days
4. **1 Month** - Long-term visibility for 30 days

## Testing

### Test Cards (Razorpay Test Mode)
- **Success**: 4111 1111 1111 1111
- **Failure**: 4000 0000 0000 0002
- **CVV**: Any 3 digits
- **Expiry**: Any future date

### Test UPI IDs
- **Success**: success@razorpay
- **Failure**: failure@razorpay

## Key Features

### In-App WebView Benefits
✅ **No External Browser** - Payment form opens inside your app  
✅ **Native App Feel** - Users stay within your app throughout  
✅ **Seamless Integration** - Looks and feels like a native payment form  
✅ **Automatic Detection** - Success/failure detected automatically  
✅ **No Dependency Issues** - Uses WebView instead of problematic Flutter SDK  

### Payment Flow
```
App Form → In-App WebView → Razorpay Form → Payment → Success Page
```

## Error Handling

The integration includes comprehensive error handling:
- Network errors
- Payment failures
- User cancellations
- Invalid amounts
- Authentication errors
- WebView loading issues

## Security Considerations

1. **Never expose your Razorpay secret key** in client-side code
2. **Use test keys** during development
3. **Verify payment signatures** on your backend
4. **Implement webhook handling** for payment status updates
5. **Store sensitive data** securely in Firestore
6. **Use HTTPS** for all payment communications

## Production Deployment

### 1. Switch to Live Keys
Replace test keys with live keys in `razorpay_inapp_service.dart`:
```dart
static const String _razorpayKey = 'rzp_live_YOUR_LIVE_KEY_HERE';
```

### 2. Enable Webhooks
Set up webhooks in Razorpay dashboard for:
- `payment.captured`
- `payment.failed`
- `refund.processed`

### 3. Update Backend URL
Change the backend URL in `razorpay_inapp_service.dart`:
```dart
static const String _backendUrl = 'https://your-production-backend.com';
```

## Troubleshooting

### Common Issues

1. **WebView not loading**
   - Check internet connectivity
   - Verify Razorpay key configuration
   - Check if JavaScript is enabled

2. **Payment not processing**
   - Check Razorpay key configuration
   - Verify backend server is running
   - Check amount format (should be in paise)

3. **Success page not showing**
   - Check payment detection logic
   - Verify Firestore permissions
   - Check navigation logic

### Debug Mode
Enable debug logging by adding:
```dart
print('Payment Debug: ${response.paymentId}');
```

## Support

For issues related to:
- **Razorpay**: Check [Razorpay Documentation](https://razorpay.com/docs/)
- **WebView**: Check [WebView Flutter Documentation](https://pub.dev/packages/webview_flutter)
- **App Integration**: Check this guide and code comments
- **Payment Issues**: Contact Razorpay support

## Next Steps

1. **Test thoroughly** with test cards
2. **Implement webhook handling** for better reliability
3. **Add payment analytics** and reporting
4. **Implement refund functionality**
5. **Add payment history** in user profile
6. **Implement subscription management** for recurring payments 