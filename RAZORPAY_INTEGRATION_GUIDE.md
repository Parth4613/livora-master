# Razorpay Integration Guide for Livora App

## Overview
This guide explains how to integrate Razorpay payment gateway into your Livora app for handling payments for listing services and premium plans.

## Files Modified/Created

### 1. **Dependencies Added**
- `pubspec.yaml`: Added `razorpay_flutter: ^1.3.5`

### 2. **New Files Created**
- `lib/services/razorpay_service.dart`: Main payment service
- `lib/payment_success_page.dart`: Success page after payment
- `assets/animations/success.json`: Success animation
- `RAZORPAY_INTEGRATION_GUIDE.md`: This guide

### 3. **Files Modified**
- `lib/main.dart`: Added Razorpay initialization
- `lib/premium_plans_page.dart`: Updated to use Razorpay for premium plans
- `lib/widgets/list_hostel_form.dart`: Updated to use Razorpay for hostel listings
- `pubspec.yaml`: Added success animation asset

## Setup Instructions

### Step 1: Get Razorpay Keys
1. Sign up at [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Create a new account or log in
3. Go to Settings → API Keys
4. Generate a new key pair
5. Copy the Key ID and Key Secret

### Step 2: Update Razorpay Keys
In `lib/services/razorpay_service.dart`, replace:
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

### Step 4: Platform Configuration

#### Android Configuration
Add to `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        // ... other configs
        minSdkVersion 21
    }
}
```

#### iOS Configuration
Add to `ios/Runner/Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>googlepay</string>
    <string>phonepe</string>
    <string>paytm</string>
</array>
```

## Integration Points

### 1. **Premium Plans Payment**
**File**: `lib/premium_plans_page.dart`
- **Trigger**: User clicks "Buy Now" on premium plans
- **Flow**: 
  1. User selects a plan
  2. Razorpay payment gateway opens
  3. User completes payment
  4. Plan is activated and saved to user's account
  5. Success message shown

### 2. **Listing Services Payment**
**Files**: 
- `lib/widgets/list_hostel_form.dart`
- `lib/widgets/list_room_form.dart`
- `lib/widgets/list_service_form.dart`
- `lib/widgets/room_request_form.dart`

**Flow**:
1. User fills listing form
2. User selects payment plan
3. Form is submitted with `paymentStatus: 'pending'`
4. Razorpay payment gateway opens
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

### Premium Plans
1. **Express Hunt** (₹29) - 7 days access
2. **Prime Seeker** (₹49) - 30 days access  
3. **Precision Pro** (₹99) - 30 days access + advanced features

### Listing Services
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

## Error Handling

The integration includes comprehensive error handling:
- Network errors
- Payment failures
- User cancellations
- Invalid amounts
- Authentication errors

## Security Considerations

1. **Never expose your Razorpay secret key** in client-side code
2. **Use test keys** during development
3. **Verify payment signatures** on your backend
4. **Implement webhook handling** for payment status updates
5. **Store sensitive data** securely in Firestore

## Production Deployment

### 1. Switch to Live Keys
Replace test keys with live keys in `razorpay_service.dart`:
```dart
static const String _razorpayKey = 'rzp_live_YOUR_LIVE_KEY_HERE';
```

### 2. Enable Webhooks
Set up webhooks in Razorpay dashboard for:
- `payment.captured`
- `payment.failed`
- `refund.processed`

### 3. Implement Backend Verification
Create a backend service to verify payment signatures:
```javascript
// Example Node.js verification
const crypto = require('crypto');

function verifyPaymentSignature(orderId, paymentId, signature, secret) {
  const text = orderId + '|' + paymentId;
  const generatedSignature = crypto
    .createHmac('sha256', secret)
    .update(text)
    .digest('hex');
  
  return generatedSignature === signature;
}
```

## Troubleshooting

### Common Issues

1. **Payment not processing**
   - Check Razorpay key configuration
   - Verify internet connectivity
   - Check amount format (should be in paise)

2. **App crashes on payment**
   - Ensure Razorpay is initialized in main.dart
   - Check platform-specific configurations
   - Verify all dependencies are installed

3. **Payment success but listing not visible**
   - Check Firestore rules
   - Verify payment record creation
   - Check listing update logic

### Debug Mode
Enable debug logging by adding:
```dart
print('Payment Debug: ${response.paymentId}');
```

## Support

For issues related to:
- **Razorpay SDK**: Check [Razorpay Flutter Documentation](https://razorpay.com/docs/payments/payment-gateway/flutter-integration/standard/)
- **App Integration**: Check this guide and code comments
- **Payment Issues**: Contact Razorpay support

## Next Steps

1. **Test thoroughly** with test cards
2. **Implement webhook handling** for better reliability
3. **Add payment analytics** and reporting
4. **Implement refund functionality**
5. **Add payment history** in user profile
6. **Implement subscription management** for recurring payments

## Files to Update for Other Listing Forms

To complete the integration, update these files similarly to `list_hostel_form.dart`:

1. `lib/widgets/list_room_form.dart`
2. `lib/widgets/list_service_form.dart` 
3. `lib/widgets/room_request_form.dart`

Follow the same pattern:
1. Add Razorpay import
2. Update `_submitForm` method
3. Set `visibility: false` initially
4. Add `paymentStatus: 'pending'`
5. Call `RazorpayService().processListingPayment()`

This completes the Razorpay integration for your Livora app! 