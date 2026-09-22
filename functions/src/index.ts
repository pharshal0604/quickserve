import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

admin.initializeApp();

export const onCustomerRequestAssigned = functions.firestore
  .document('requests/{requestId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (newData.status === 'assigned' && oldData.status !== 'assigned') {
      const customerId = newData.customerId;
      const agentName = newData.agentName;

      const customerDoc = await getFirestore().collection('users').doc(customerId).get();
      const customerData = customerDoc.data();
      
      if (!customerData || !customerData.fcmTokens || customerData.fcmTokens.length === 0) {
        console.log('No FCM tokens found for customer:', customerId);
        return null;
      }

      const message = {
        notification: {
          title: 'Request Assigned',
          body: `${agentName} has been assigned to your request!`,
        },
        tokens: customerData.fcmTokens,
      };

      try {
        const response = await getMessaging().sendEachForMulticast(message);
        console.log(`Successfully sent ${response.successCount} messages.`);
      } catch (error) {
        console.error('Error sending notification:', error);
      }
    }
    return null;
  });
