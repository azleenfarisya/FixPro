const express = require('express');
const app = express();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const cors = require('cors');
const admin = require('firebase-admin');

// Parse JSON for normal endpoints
app.use(cors());
app.use(express.json());

// Stripe webhook needs raw body
app.post('/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.log('Webhook signature verification failed.', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle successful payment
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    try {
      // Initialize Firebase Admin if not already
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)),
        });
      }
      const db = admin.firestore();
      await db.collection('payments').add({
        amount: session.amount_total / 100,
        currency: session.currency,
        status: 'Paid',
        stripeSessionId: session.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log('Payment saved to Firestore!');
    } catch (e) {
      console.log('Firestore error:', e);
    }
  }

  res.json({received: true});
});

// Normal JSON parsing for other endpoints
app.use(express.json());

app.post('/create-checkout-session', async (req, res) => {
  const { amount, currency } = req.body;
  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency,
          product_data: {
            name: 'FixUp Pro Payment',
          },
          unit_amount: amount,
        },
        quantity: 1,
      }],
      mode: 'payment',
      success_url: 'https://your-flutter-app.com/payment-success', // <-- change to your deployed Flutter web app
      cancel_url: 'https://your-flutter-app.com/payment-cancel',   // <-- change to your deployed Flutter web app
    });
    res.json({ url: session.url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 4242;
app.listen(PORT, () => console.log('Running on port ' + PORT));