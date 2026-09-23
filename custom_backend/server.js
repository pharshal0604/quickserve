require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

// Initialize Firebase Admin
// Render will use the GOOGLE_APPLICATION_CREDENTIALS environment variable
// which points to the service account JSON file.
if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
  const serviceAccount = JSON.parse(Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('ascii'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  // Fallback for local development if a serviceAccountKey.json is present
  try {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } catch (e) {
    console.log('Warning: No Firebase credentials found. Push notifications will fail.');
  }
}

const app = express();
app.use(cors());
app.use(express.json());

// Health check endpoint for Render
app.get('/', (req, res) => {
  res.send('QuickServe Notification Server is running!');
});

// Endpoint to trigger agent assigned notification
app.post('/api/notify-assignment', async (req, res) => {
  try {
    const { customerId, agentName } = req.body;

    if (!customerId || !agentName) {
      return res.status(400).json({ error: 'Missing customerId or agentName' });
    }

    const customerDoc = await admin.firestore().collection('users').doc(customerId).get();
    const customerData = customerDoc.data();
    
    if (!customerData || !customerData.fcmTokens || customerData.fcmTokens.length === 0) {
      return res.status(404).json({ error: 'No FCM tokens found for customer' });
    }

    const message = {
      notification: {
        title: 'Request Assigned',
        body: `${agentName} has been assigned to your request!`,
      },
      tokens: customerData.fcmTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    res.json({ success: true, response });

  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
