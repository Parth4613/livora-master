# Payment Integration Setup Guide

## Overview
This project uses a **hybrid payment approach** to ensure compliance with both Google Play Store policies and web deployment requirements.

## Payment Architecture

### Mobile (Android/iOS)
- **Premium Plans**: Google Play Billing (mandatory for digital goods)
- **Listing Payments**: Razorpay (allowed for services)

### Web
- **All Payments**: Razorpay (external payments allowed)

## Setup Requirements

### 1. Google Play Console Setup (Mobile)

#### Create In-App Products
1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to **Monetization** > **Products** > **In-app products**
3. Create the following products:

```
Product ID: express_hunt_plan
Name: Express Hunt Plan
Description: 7-day premium access
Price: ₹29.00

Product ID: prime_seeker_plan  
Name: Prime Seeker Plan
Description: 30-day premium access
Price: ₹49.00

Product ID: precision_pro_plan
Name: Precision Pro Plan
Description: 30-day premium access with location features
Price: ₹99.00
```

#### Configure Billing
1. Enable **Google Play Billing** in your app
2. Add billing permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### 2. Razorpay Setup

#### Get API Keys
1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Navigate to **Settings** > **API Keys**
3. Generate new API keys for production

#### Update Configuration
Replace the test keys in `lib/services/efficient_payment_service.dart`:
```dart
static const String _razorpayKey = 'rzp_live_YOUR_LIVE_KEY';
static const String _razorpaySecret = 'YOUR_LIVE_SECRET';
```

### 3. Backend API Setup (Recommended)

For production, create a backend API to handle:
- Order creation
- Payment signature verification
- Webhook processing

#### Example Backend Endpoints
```
POST /api/orders/create
POST /api/payments/verify
POST /api/webhooks/razorpay
```

## Current Implementation Status

### ✅ Completed
- [x] Payment service architecture
- [x] Google Play Billing service (simulated)
- [x] Razorpay web integration
- [x] Cross-platform payment routing
- [x] Payment success handling
- [x] Plan activation logic

### ⚠️ Needs Implementation
- [x] ✅ Real Google Play Billing integration (in_app_purchase)
- [x] ✅ Backend API for order management (Node.js/Express)
- [x] ✅ Payment signature verification
- [x] ✅ Webhook handling
- [ ] Production API keys (replace test keys)
- [ ] Production deployment
- [ ] Comprehensive testing on real devices

## Testing

### Mobile Testing
1. Use test accounts in Google Play Console
2. Test with sandbox environment
3. Verify plan activation

### Web Testing
1. Use Razorpay test mode
2. Test payment flow in browser
3. Verify success handling

## Deployment Checklist

### Before Google Play Store Submission
- [x] ✅ Implement real Google Play Billing (in_app_purchase)
- [x] ✅ Set up backend API for Razorpay
- [x] ✅ Add proper error handling
- [x] ✅ Implement payment verification
- [ ] Replace test API keys with production keys
- [ ] Test payment flows thoroughly on real devices
- [ ] Ensure compliance with Play Store policies
- [ ] Configure Google Play Console products
- [ ] Set up test accounts for billing

### Before Web Deployment
- [x] ✅ Set up backend API (Node.js/Express)
- [x] ✅ Configure Razorpay integration
- [x] ✅ Add proper error handling
- [ ] Replace test API keys with production keys
- [ ] Deploy backend to production server
- [ ] Configure production webhooks
- [ ] Test payment flows on web browsers
- [ ] Set up monitoring and logging

## Compliance Notes

### Google Play Store
- ✅ Premium plans use Google Play Billing
- ✅ Listing payments are for services (allowed)
- ✅ No external payment links for digital goods

### Web Deployment
- ✅ External payments are allowed
- ✅ Razorpay integration is compliant
- ✅ Proper user experience maintained

## Troubleshooting

### Common Issues
1. **Payment not processing**: Check API keys and network connectivity
2. **Plan not activating**: Verify Firestore permissions and data structure
3. **Google Play Billing errors**: Ensure proper product configuration
4. **Web payment issues**: Check Razorpay configuration and browser compatibility

### Support
- Google Play Billing: [Official Documentation](https://developer.android.com/google/play/billing)
- Razorpay: [Official Documentation](https://razorpay.com/docs/)
- Flutter In-App Purchase: [Package Documentation](https://pub.dev/packages/in_app_purchase) 