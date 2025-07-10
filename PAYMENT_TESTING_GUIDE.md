# Payment Testing Guide

## Overview
This guide covers testing all payment flows in your app across different platforms and environments.

## Prerequisites

### 1. Backend Setup
```bash
cd razorpay-backend
npm install
cp env.example .env
# Edit .env with your Razorpay test keys
npm run dev
```

### 2. Flutter App Setup
```bash
flutter pub get
flutter run
```

## Testing Checklist

### ✅ Google Play Billing (Mobile Premium Plans)

#### Test Environment Setup
1. **Google Play Console Setup:**
   - Create test account in Google Play Console
   - Add test email to license testing
   - Create in-app products with test SKUs:
     - `express_hunt_plan` (₹29)
     - `prime_seeker_plan` (₹49)
     - `precision_pro_plan` (₹99)

2. **Android Device Setup:**
   - Use test device with Google Play Services
   - Sign in with test Google account
   - Enable developer options

#### Test Cases
- [ ] **Express Hunt Plan Purchase**
  - Navigate to Premium Plans page
  - Tap "Express Hunt" plan
  - Verify Google Play billing dialog appears
  - Complete purchase with test card
  - Verify plan activation in Firestore
  - Check success page navigation

- [ ] **Prime Seeker Plan Purchase**
  - Same flow as above
  - Verify 30-day duration activation

- [ ] **Precision Pro Plan Purchase**
  - Same flow as above
  - Verify premium features unlock

- [ ] **Purchase Failure Handling**
  - Test with invalid payment method
  - Verify error messages
  - Check app state recovery

- [ ] **Purchase Restoration**
  - Test app restart after purchase
  - Verify plan remains active
  - Check purchase history

### ✅ Razorpay Web Payments (Web Premium Plans)

#### Test Environment Setup
1. **Razorpay Dashboard:**
   - Use test mode API keys
   - Configure webhook URL (if testing locally, use ngrok)
   - Set up test payment methods

2. **Web Browser Setup:**
   - Use Chrome/Firefox with developer tools
   - Enable network monitoring
   - Test on different screen sizes

#### Test Cases
- [ ] **Premium Plan Purchase (Web)**
  - Open app in browser
  - Navigate to Premium Plans
  - Click "Buy" on any plan
  - Verify Razorpay checkout opens
  - Complete payment with test card
  - Verify success page and plan activation

- [ ] **Payment Method Testing**
  - Test with different cards (Visa, MasterCard, RuPay)
  - Test with UPI
  - Test with net banking
  - Test with wallets (Paytm, PhonePe)

- [ ] **Payment Failure Scenarios**
  - Test with insufficient funds
  - Test with expired cards
  - Test with 3D Secure failures
  - Verify error handling

### ✅ Listing Payments (Mobile & Web)

#### Test Cases
- [ ] **Hostel Listing Payment**
  - Fill hostel listing form
  - Submit with payment
  - Verify Razorpay checkout opens
  - Complete payment
  - Verify listing becomes visible

- [ ] **Room Listing Payment**
  - Fill room listing form
  - Submit with payment
  - Verify payment flow
  - Check listing activation

- [ ] **Service Listing Payment**
  - Fill service listing form
  - Submit with payment
  - Verify payment completion
  - Check service visibility

- [ ] **Room Request Payment**
  - Fill room request form
  - Submit with payment
  - Verify payment processing
  - Check request submission

### ✅ Backend API Testing

#### Test Environment
```bash
# Start backend server
cd razorpay-backend
npm run dev

# Test endpoints
curl http://localhost:3000/health
```

#### Test Cases
- [ ] **Order Creation**
  ```bash
  curl -X POST http://localhost:3000/api/orders/create \
    -H "Content-Type: application/json" \
    -d '{
      "amount": 990,
      "currency": "INR",
      "receipt": "test_receipt_123",
      "notes": {
        "planName": "Precision Pro",
        "userId": "test_user_123"
      }
    }'
  ```

- [ ] **Payment Verification**
  ```bash
  curl -X POST http://localhost:3000/api/payments/verify \
    -H "Content-Type: application/json" \
    -d '{
      "razorpay_order_id": "order_123",
      "razorpay_payment_id": "pay_123",
      "razorpay_signature": "signature_123"
    }'
  ```

- [ ] **Payment Details**
  ```bash
  curl http://localhost:3000/api/payments/pay_123
  ```

### ✅ Cross-Platform Testing

#### Mobile Testing
- [ ] **Android Physical Device**
  - Test on real Android device
  - Verify Google Play billing
  - Test listing payments
  - Check offline behavior

- [ ] **iOS Simulator/Device**
  - Test on iOS simulator
  - Verify payment flows
  - Check UI responsiveness

#### Web Testing
- [ ] **Desktop Browsers**
  - Chrome, Firefox, Safari, Edge
  - Different screen resolutions
  - Network throttling

- [ ] **Mobile Browsers**
  - Chrome Mobile, Safari Mobile
  - Test responsive design
  - Verify touch interactions

### ✅ Error Handling Testing

#### Network Issues
- [ ] **No Internet Connection**
  - Disconnect network
  - Try payment operations
  - Verify error messages
  - Test reconnection handling

- [ ] **Slow Network**
  - Use network throttling
  - Test timeout scenarios
  - Verify loading states

#### Payment Failures
- [ ] **Invalid Cards**
  - Test with fake card numbers
  - Verify validation errors
  - Check user feedback

- [ ] **Declined Payments**
  - Test with declined cards
  - Verify error handling
  - Check retry mechanisms

### ✅ Security Testing

#### Payment Security
- [ ] **Signature Verification**
  - Verify payment signatures
  - Test with invalid signatures
  - Check fraud prevention

- [ ] **API Security**
  - Test rate limiting
  - Verify CORS settings
  - Check input validation

#### Data Security
- [ ] **Sensitive Data**
  - Verify no card data in logs
  - Check secure transmission
  - Test data encryption

## Test Data

### Test Cards (Razorpay)
```
Card Number: 4111 1111 1111 1111
Expiry: Any future date
CVV: Any 3 digits
Name: Any name
```

### Test UPI
```
UPI ID: success@razorpay
```

### Test Net Banking
```
Bank: Any test bank
Credentials: Use test credentials
```

## Debugging

### Common Issues

1. **Google Play Billing Not Working**
   - Check test account setup
   - Verify product IDs
   - Check device compatibility

2. **Razorpay Payment Fails**
   - Verify API keys
   - Check network connectivity
   - Review error logs

3. **Backend Connection Issues**
   - Check server status
   - Verify CORS settings
   - Check firewall settings

### Logs to Monitor

#### Flutter App
```dart
// Add debug logs
print('Payment initiated: $planName');
print('Order created: ${order['id']}');
print('Payment completed: $paymentId');
```

#### Backend Server
```bash
# Monitor server logs
npm run dev
# Check for errors in console
```

#### Razorpay Dashboard
- Monitor payment attempts
- Check webhook deliveries
- Review error logs

## Performance Testing

### Load Testing
- [ ] **Concurrent Payments**
  - Test multiple simultaneous payments
  - Verify backend performance
  - Check rate limiting

- [ ] **Large Order Volumes**
  - Test with many orders
  - Verify database performance
  - Check memory usage

### Stress Testing
- [ ] **High Traffic**
  - Simulate high user load
  - Test payment processing
  - Verify system stability

## Production Readiness Checklist

### Before Go-Live
- [ ] Replace test API keys with production keys
- [ ] Configure production webhooks
- [ ] Set up monitoring and alerts
- [ ] Test with real payment methods
- [ ] Verify compliance requirements
- [ ] Set up backup systems
- [ ] Configure error reporting
- [ ] Test disaster recovery

### Post-Launch Monitoring
- [ ] Monitor payment success rates
- [ ] Track error rates
- [ ] Monitor response times
- [ ] Check fraud patterns
- [ ] Review user feedback
- [ ] Monitor system health

## Support Resources

- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [Razorpay Documentation](https://razorpay.com/docs/)
- [Flutter In-App Purchase](https://pub.dev/packages/in_app_purchase)
- [Express.js Documentation](https://expressjs.com/) 