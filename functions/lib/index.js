"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onCustomerRequestAssigned = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
admin.initializeApp();
exports.onCustomerRequestAssigned = functions.firestore
    .document('requests/{requestId}')
    .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    if (newData.status === 'assigned' && oldData.status !== 'assigned') {
        const customerId = newData.customerId;
        const agentName = newData.agentName;
        const customerDoc = await (0, firestore_1.getFirestore)().collection('users').doc(customerId).get();
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
            const response = await (0, messaging_1.getMessaging)().sendEachForMulticast(message);
            console.log(`Successfully sent ${response.successCount} messages.`);
        }
        catch (error) {
            console.error('Error sending notification:', error);
        }
    }
    return null;
});
//# sourceMappingURL=index.js.map