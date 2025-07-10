# Razorpay Backend Server

A Node.js/Express backend server for handling Razorpay payment operations including order creation, payment verification, and webhook processing.

## Features

- ✅ Order creation with Razorpay
- ✅ Payment signature verification
- ✅ Webhook processing for payment events
- ✅ Security middleware (Helmet, CORS, Rate limiting)
- ✅ Environment-based configuration
- ✅ Health check endpoint
- ✅ Error handling and logging

## Setup Instructions

### 1. Install Dependencies

```bash
cd razorpay-backend
npm install
```

### 2. Environment Configuration

Copy the environment template and configure your settings:

```bash
cp env.example .env
```

Edit `.env` with your Razorpay credentials:

```env
# Razorpay Configuration
RAZORPAY_KEY_ID=rzp_test_YOUR_TEST_KEY
RAZORPAY_KEY_SECRET=YOUR_TEST_SECRET

# For production, use live keys:
# RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY
# RAZORPAY_KEY_SECRET=YOUR_LIVE_SECRET

# Server Configuration
PORT=3000
NODE_ENV=development

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,https://your-app-domain.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 3. Get Razorpay API Keys

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Navigate to **Settings** > **API Keys**
3. Generate new API keys for your environment
4. Update the `.env` file with your keys

### 4. Start the Server

**Development mode:**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on `http://localhost:3000`

## API Endpoints

### Health Check
```
GET /health
```

### Create Order
```
POST /api/orders/create
Content-Type: application/json

{
  "amount": 1000,
  "currency": "INR",
  "receipt": "receipt_123",
  "notes": {
    "planName": "Premium Plan",
    "userId": "user123"
  }
}
```

### Verify Payment
```
POST /api/payments/verify
Content-Type: application/json

{
  "razorpay_order_id": "order_123",
  "razorpay_payment_id": "pay_123",
  "razorpay_signature": "signature_123"
}
```

### Get Payment Details
```
GET /api/payments/:payment_id
```

### Webhook (Razorpay Events)
```
POST /api/webhooks/razorpay
```

## Integration with Flutter App

Update your `efficient_payment_service.dart` to use this backend:

```dart
// Replace the mock order creation with real API call
Future<Map<String, dynamic>> _createOrder(String planName, double amount, String userId) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/api/orders/create'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'amount': amount,
      'currency': 'INR',
      'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
      'notes': {
        'planName': planName,
        'userId': userId,
        'type': 'premium_plan',
      },
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['order'];
  } else {
    throw Exception('Failed to create order');
  }
}
```

## Security Features

- **Helmet**: Security headers
- **CORS**: Cross-origin resource sharing protection
- **Rate Limiting**: Prevents abuse
- **Signature Verification**: Ensures payment authenticity
- **Environment Variables**: Secure configuration management

## Webhook Setup

1. In your Razorpay Dashboard, go to **Settings** > **Webhooks**
2. Add webhook URL: `https://your-domain.com/api/webhooks/razorpay`
3. Select events: `payment.captured`, `payment.failed`, `order.paid`
4. Copy the webhook secret and add to `.env`:
   ```env
   RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
   ```

## Production Deployment

### Using PM2
```bash
npm install -g pm2
pm2 start server.js --name "razorpay-backend"
pm2 save
pm2 startup
```

### Using Docker
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Environment Variables for Production
```env
NODE_ENV=production
PORT=3000
RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY
RAZORPAY_KEY_SECRET=YOUR_LIVE_SECRET
ALLOWED_ORIGINS=https://your-app-domain.com
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
```

## Testing

### Test the API endpoints:

```bash
# Health check
curl http://localhost:3000/health

# Create order
curl -X POST http://localhost:3000/api/orders/create \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "receipt": "test_123"}'

# Verify payment (use actual payment details from Razorpay)
curl -X POST http://localhost:3000/api/payments/verify \
  -H "Content-Type: application/json" \
  -d '{"razorpay_order_id": "order_123", "razorpay_payment_id": "pay_123", "razorpay_signature": "signature_123"}'
```

## Troubleshooting

### Common Issues

1. **CORS Errors**: Update `ALLOWED_ORIGINS` in `.env`
2. **Payment Verification Fails**: Check Razorpay keys and signature
3. **Webhook Not Working**: Verify webhook URL and secret
4. **Rate Limiting**: Adjust limits in `.env` if needed

### Logs
Check server logs for detailed error information:
```bash
# If using PM2
pm2 logs razorpay-backend

# If using Docker
docker logs container_name
```

## Support

- [Razorpay Documentation](https://razorpay.com/docs/)
- [Express.js Documentation](https://expressjs.com/)
- [Node.js Documentation](https://nodejs.org/) 