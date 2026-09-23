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

// Helper to send push notification to a specific user by UID
async function sendNotificationToUser(userId, title, body, data = {}) {
  try {
    // 1. Save to in-app notification history (Firestore)
    await admin.firestore().collection('users').doc(userId).collection('notifications').add({
      title,
      body,
      data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 2. Send actual push notification via FCM
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    const userData = userDoc.data();
    if (!userData || !userData.fcmTokens || userData.fcmTokens.length === 0) {
      console.log(`No FCM tokens found for user: ${userId}`);
      return null;
    }

    const message = {
      notification: { title, body },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      tokens: userData.fcmTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`Sent notification to ${userId}: ${response.successCount} succeeded, ${response.failureCount} failed.`);
    return response;
  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
    return null;
  }
}

// Endpoint to trigger agent assigned notification (backward compatibility)
app.post('/api/notify-assignment', async (req, res) => {
  try {
    const { customerId, agentName, agentId, serviceName } = req.body;

    if (!customerId || !agentName) {
      return res.status(400).json({ error: 'Missing customerId or agentName' });
    }

    // 1. Notify Customer
    const customerRes = await sendNotificationToUser(
      customerId,
      'Agent Assigned 🚚',
      `${agentName} has been assigned to your request!`
    );

    // 2. Notify Agent (if agentId provided)
    if (agentId) {
      await sendNotificationToUser(
        agentId,
        'New Request Assigned 📋',
        `You have been assigned a new request${serviceName ? ` for ${serviceName}` : ''}.`
      );
    }

    res.json({ success: true, response: customerRes });
  } catch (error) {
    console.error('Error sending assignment notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Comprehensive Notification Endpoint for status changes
app.post('/api/notify-status-change', async (req, res) => {
  try {
    const { status, customerId, agentId, agentName, customerName, serviceName, requestId } = req.body;

    if (!status) {
      return res.status(400).json({ error: 'Missing status' });
    }

    let results = [];

    switch (status) {
      case 'created':
        // Notify Agent / Admins if needed
        if (agentId) {
          const r = await sendNotificationToUser(
            agentId,
            'New Request 🆕',
            `${customerName || 'A customer'} placed a request for ${serviceName || 'a service'}.`,
            { requestId: requestId || '' }
          );
          results.push(r);
        }
        break;

      case 'assigned':
        if (customerId) {
          const r1 = await sendNotificationToUser(
            customerId,
            'Agent Assigned 🚚',
            `${agentName || 'An agent'} has been assigned to your request.`,
            { requestId: requestId || '' }
          );
          results.push(r1);
        }
        if (agentId) {
          const r2 = await sendNotificationToUser(
            agentId,
            'New Job Assigned 📋',
            `You have been assigned to service request ${serviceName ? `(${serviceName})` : ''}.`,
            { requestId: requestId || '' }
          );
          results.push(r2);
        }
        break;

      case 'accepted':
        if (customerId) {
          const r = await sendNotificationToUser(
            customerId,
            'Request Accepted ✅',
            `${agentName || 'Your agent'} accepted your request and is preparing for service.`,
            { requestId: requestId || '' }
          );
          results.push(r);
        }
        break;

      case 'in_progress':
        if (customerId) {
          const r = await sendNotificationToUser(
            customerId,
            'Service In Progress 🛠️',
            `${agentName || 'Your agent'} has started working on your request.`,
            { requestId: requestId || '' }
          );
          results.push(r);
        }
        break;

      case 'completed':
        if (customerId) {
          const r = await sendNotificationToUser(
            customerId,
            'Service Completed 🎉',
            'Your service request has been completed! Thank you for using QuickServe.',
            { requestId: requestId || '' }
          );
          results.push(r);
        }
        break;

      case 'cancelled':
        if (customerId) {
          const r1 = await sendNotificationToUser(
            customerId,
            'Request Cancelled ❌',
            'Your service request has been cancelled.',
            { requestId: requestId || '' }
          );
          results.push(r1);
        }
        if (agentId) {
          const r2 = await sendNotificationToUser(
            agentId,
            'Request Cancelled ❌',
            `The service request${serviceName ? ` for ${serviceName}` : ''} has been cancelled.`,
            { requestId: requestId || '' }
          );
          results.push(r2);
        }
        break;

      default:
        console.log(`Unhandled status: ${status}`);
    }

    res.json({ success: true, count: results.length });
  } catch (error) {
    console.error('Error in notify-status-change:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
