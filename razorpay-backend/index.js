const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const Razorpay = require('razorpay');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Razorpay
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_O9xBxveMFHkkdp',
  key_secret: process.env.RAZORPAY_KEY_SECRET || '540ObIojNTJlPoQMdZsdXoyX',
});

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Razorpay Backend is running',
    timestamp: new Date().toISOString(),
  });
});

// Create order endpoint
app.post('/api/orders/create', async (req, res) => {
  try {
    const { amount, currency = 'INR', receipt, notes } = req.body;

    // Validate required fields
    if (!amount || !receipt) {
      return res.status(400).json({
        error: 'amount and receipt are required',
      });
    }

    // Validate amount (should be in paise for Razorpay)
    const amountInPaise = parseInt(amount, 10);
    if (isNaN(amountInPaise) || amountInPaise <= 0) {
      return res.status(400).json({
        error: 'amount must be greater than 0 and a valid number',
      });
    }

    // Create Razorpay order
    const orderOptions = {
      amount: amountInPaise,
      currency: currency,
      receipt: receipt,
      notes: notes || {},
    };

    const order = await razorpay.orders.create(orderOptions);

    console.log('Order created successfully:', order.id);

    res.json({
      success: true,
      order: {
        id: order.id,
        amount: order.amount,
        currency: order.currency,
        receipt: order.receipt,
        status: order.status,
        notes: order.notes,
      },
    });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({
      error: 'Failed to create order',
      details: error.message,
    });
  }
});

// Verify payment endpoint
app.post('/api/payments/verify', async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    // Validate required fields
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({
        error: 'razorpay_order_id, razorpay_payment_id, and razorpay_signature are required',
      });
    }

    // Verify signature
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || '540ObIojNTJlPoQMdZsdXoyX')
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    if (expectedSignature === razorpay_signature) {
      res.json({
        success: true,
        message: 'Payment verified successfully',
        paymentId: razorpay_payment_id,
        orderId: razorpay_order_id,
      });
    } else {
      res.status(400).json({
        error: 'Invalid signature',
      });
    }
  } catch (error) {
    console.error('Error verifying payment:', error);
    res.status(500).json({
      error: 'Failed to verify payment',
      details: error.message,
    });
  }
});

// Webhook endpoint for payment events
app.post('/api/webhooks/razorpay', async (req, res) => {
  try {
    const { event, payload } = req.body;

    console.log('Webhook received:', event);

    // Verify webhook signature (in production, always verify)
    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (webhookSecret) {
      const crypto = require('crypto');
      const signature = req.headers['x-razorpay-signature'];
      const expectedSignature = crypto
        .createHmac('sha256', webhookSecret)
        .update(JSON.stringify(req.body))
        .digest('hex');

      if (signature !== expectedSignature) {
        console.error('Invalid webhook signature');
        return res.status(400).json({ error: 'Invalid signature' });
      }
    }

    // Handle different webhook events
    switch (event) {
      case 'payment.captured':
        console.log('Payment captured:', payload.payment.entity.id);
        // Here you can update your database, send notifications, etc.
        break;
      
      case 'payment.failed':
        console.log('Payment failed:', payload.payment.entity.id);
        // Handle failed payment
        break;
      
      default:
        console.log('Unhandled webhook event:', event);
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).json({
      error: 'Failed to process webhook',
      details: error.message,
    });
  }
});

// Create Razorpay Payment Link endpoint
app.post('/api/payment-links/create', async (req, res) => {
  try {
    const { amount, currency = 'INR', description = 'Test Payment', customer = {} } = req.body;
    if (!amount || !description) {
      return res.status(400).json({ error: 'amount and description are required' });
    }

    // Prepare payment link options
    const options = {
      amount: Math.round(amount * 100), // Razorpay expects paise
      currency,
      description,
      customer,
      notify: { sms: true, email: true },
      reminder_enable: true,
      callback_url: 'https://example.com/payment-success', // Optional: replace with your app's callback
      callback_method: 'get',
    };

    const paymentLink = await razorpay.paymentLink.create(options);
    res.json({ success: true, payment_link: paymentLink });
  } catch (error) {
    console.error('Error creating payment link:', error);
    res.status(500).json({ error: 'Failed to create payment link', details: error.message });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    details: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong',
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.originalUrl,
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Razorpay Backend Server running on port ${PORT}`);
  console.log(`📊 Health check: http://152.58.15.6:${PORT}/health`);
  console.log(`🔗 API Base URL: http://152.58.15.6:${PORT}/api`);
  console.log(`📱 Device access: http://10.92.18.47:${PORT}/api`);
});

module.exports = app;