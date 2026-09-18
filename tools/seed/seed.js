const admin = require('firebase-admin');

const SEED_PASSWORD = process.env.SEED_PASSWORD || 'TestSeed-2026!';

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error('FIRESTORE_EMULATOR_HOST must point to the Firestore Emulator.');
}

if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error(
    'FIREBASE_AUTH_EMULATOR_HOST must point to the Authentication Emulator.',
  );
}

admin.initializeApp({ projectId: 'quickserve-78e40' });

const db = admin.firestore();
const auth = admin.auth();
const Timestamp = admin.firestore.Timestamp;

const users = [
  {
    uid: 'customer-uid-001',
    role: 'customer',
    name: 'Aarav Sharma',
    email: 'customer1@example.test',
    phone: '+91-9000000001',
  },
  {
    uid: 'customer-uid-002',
    role: 'customer',
    name: 'Diya Patil',
    email: 'customer2@example.test',
    phone: '+91-9000000002',
  },
  {
    uid: 'agent-uid-001',
    role: 'agent',
    name: 'Rohan Deshmukh',
    email: 'agent1@example.test',
    phone: '+91-9000000003',
  },
  {
    uid: 'agent-uid-002',
    role: 'agent',
    name: 'Meera Joshi',
    email: 'agent2@example.test',
    phone: '+91-9000000004',
  },
  {
    uid: 'admin-uid-001',
    role: 'admin',
    name: 'Operations Admin',
    email: 'admin@example.test',
    phone: '+91-9000000005',
  },
];

const services = [
  {
    id: 'ac_servicing',
    name: 'AC servicing',
    description: 'Inspection, cleaning, and maintenance of AC units.',
    active: true,
  },
  {
    id: 'plumbing',
    name: 'Plumbing',
    description: 'Leak repair, pipe fitting, and general plumbing work.',
    active: true,
  },
  {
    id: 'electrical',
    name: 'Electrical',
    description: 'Wiring, switchboard, and general electrical work.',
    active: true,
  },
  {
    id: 'cleaning',
    name: 'Cleaning',
    description: 'Deep cleaning for rooms, kitchens, and bathrooms.',
    active: true,
  },
  {
    id: 'inactive_service',
    name: 'Archived Service (do not select)',
    description: 'Synthetic inactive service for UI testing.',
    active: false,
  },
];

const requests = [
  {
    id: 'request-doc-001',
    requestCode: 'REQ-2026-000001',
    customerId: 'customer-uid-001',
    agentId: null,
    serviceType: 'AC servicing',
    status: 'created',
    priority: 'medium',
  },
  {
    id: 'request-doc-002',
    requestCode: 'REQ-2026-000002',
    customerId: 'customer-uid-001',
    agentId: 'agent-uid-001',
    serviceType: 'Plumbing',
    status: 'assigned',
    priority: 'high',
  },
  {
    id: 'request-doc-003',
    requestCode: 'REQ-2026-000003',
    customerId: 'customer-uid-001',
    agentId: 'agent-uid-001',
    serviceType: 'Electrical',
    status: 'accepted',
    priority: 'low',
  },
  {
    id: 'request-doc-004',
    requestCode: 'REQ-2026-000004',
    customerId: 'customer-uid-001',
    agentId: 'agent-uid-001',
    serviceType: 'Cleaning',
    status: 'in_progress',
    priority: 'medium',
  },
  {
    id: 'request-doc-005',
    requestCode: 'REQ-2026-000005',
    customerId: 'customer-uid-001',
    agentId: 'agent-uid-001',
    serviceType: 'AC servicing',
    status: 'completed',
    priority: 'high',
  },
  {
    id: 'request-doc-006',
    requestCode: 'REQ-2026-000006',
    customerId: 'customer-uid-002',
    agentId: null,
    serviceType: 'Plumbing',
    status: 'cancelled',
    priority: 'low',
    cancellationReason: 'Synthetic cancellation reason.',
  },
  {
    id: 'request-doc-007',
    requestCode: 'REQ-2026-000007',
    customerId: 'customer-uid-002',
    agentId: 'agent-uid-002',
    serviceType: 'Electrical',
    status: 'assigned',
    priority: 'medium',
  },
];

const historyByRequest = {
  'request-doc-001': [
    [null, 'created', 'customer-uid-001', 'Request created.'],
  ],
  'request-doc-002': [
    [null, 'created', 'customer-uid-001', 'Request created.'],
    ['created', 'assigned', 'admin-uid-001', 'Assigned to agent.'],
  ],
  'request-doc-003': [
    [null, 'created', 'customer-uid-001', 'Request created.'],
    ['created', 'assigned', 'admin-uid-001', 'Assigned to agent.'],
    ['assigned', 'accepted', 'agent-uid-001', 'Agent accepted request.'],
  ],
  'request-doc-004': [
    [null, 'created', 'customer-uid-001', 'Request created.'],
    ['created', 'assigned', 'admin-uid-001', 'Assigned to agent.'],
    ['assigned', 'accepted', 'agent-uid-001', 'Agent accepted request.'],
    ['accepted', 'in_progress', 'agent-uid-001', 'Work started.'],
  ],
  'request-doc-005': [
    [null, 'created', 'customer-uid-001', 'Request created.'],
    ['created', 'assigned', 'admin-uid-001', 'Assigned to agent.'],
    ['assigned', 'accepted', 'agent-uid-001', 'Agent accepted request.'],
    ['accepted', 'in_progress', 'agent-uid-001', 'Work started.'],
    ['in_progress', 'completed', 'agent-uid-001', 'Work completed.'],
  ],
  'request-doc-006': [
    [null, 'created', 'customer-uid-002', 'Request created.'],
    [
      'created',
      'cancelled',
      'customer-uid-002',
      'Synthetic cancellation reason.',
    ],
  ],
  'request-doc-007': [
    [null, 'created', 'customer-uid-002', 'Request created.'],
    ['created', 'assigned', 'admin-uid-001', 'Assigned to agent.'],
  ],
};

function timestampWithOffset(milliseconds) {
  return Timestamp.fromMillis(Timestamp.now().toMillis() - milliseconds);
}

async function ensureAuthUser(user) {
  try {
    const existing = await auth.getUserByEmail(user.email);
    if (existing.uid !== user.uid) {
      throw new Error(
        `Email ${user.email} already belongs to UID ${existing.uid}, not ${user.uid}.`,
      );
    }
    return existing;
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    return auth.createUser({
      uid: user.uid,
      email: user.email,
      password: SEED_PASSWORD,
      displayName: user.name,
    });
  }
}

async function seedUsers() {
  const timestamp = Timestamp.now();

  for (const user of users) {
    await ensureAuthUser(user);
    await db.collection('users').doc(user.uid).set(
      {
        role: user.role,
        name: user.name,
        email: user.email,
        phone: user.phone,
        createdAt: timestamp,
        updatedAt: timestamp,
      },
      { merge: true },
    );
  }

  console.log('Seeded 5 users.');
}

async function seedServices() {
  const timestamp = Timestamp.now();

  for (const service of services) {
    await db.collection('services').doc(service.id).set(
      {
        name: service.name,
        description: service.description,
        active: service.active,
        createdAt: timestamp,
      },
      { merge: true },
    );
  }

  console.log('Seeded 5 services.');
}

async function seedRequests() {
  const timestamp = Timestamp.now();

  for (const request of requests) {
    await db.collection('requests').doc(request.id).set(
      {
        requestCode: request.requestCode,
        customerId: request.customerId,
        agentId: request.agentId,
        serviceType: request.serviceType,
        description: 'Synthetic description for testing.',
        preferredDateTime: timestamp,
        address: 'Synthetic address for testing.',
        priority: request.priority,
        status: request.status,
        createdAt: timestamp,
        updatedAt: timestamp,
        cancellationReason: request.cancellationReason || null,
      },
      { merge: true },
    );
  }

  console.log('Seeded 7 requests.');
}

async function seedStatusHistory() {
  for (const request of requests) {
    const history = historyByRequest[request.id];

    for (let index = 0; index < history.length; index += 1) {
      const [fromStatus, toStatus, changedBy, note] = history[index];
      const historyId = `history-${String(index + 1).padStart(4, '0')}`;

      await db
        .collection('requests')
        .doc(request.id)
        .collection('status_history')
        .doc(historyId)
        .set(
          {
            fromStatus,
            toStatus,
            changedBy,
            changedAt: timestampWithOffset((history.length - index) * 1000),
            note,
          },
          { merge: true },
        );
    }
  }

  console.log('Seeded status history for 7 requests.');
}

async function seedAuditLogs() {
  const auditLogs = [
    {
      id: 'audit-login-success',
      actorUserId: 'customer-uid-001',
      actorRole: 'customer',
      action: 'LOGIN_SUCCESS',
      targetType: 'user',
      targetId: 'customer-uid-001',
      oldValue: {},
      newValue: {},
      result: 'success',
    },
    {
      id: 'audit-request-created',
      actorUserId: 'customer-uid-001',
      actorRole: 'customer',
      action: 'REQUEST_CREATED',
      targetType: 'request',
      targetId: 'request-doc-001',
      oldValue: {},
      newValue: { status: 'created' },
      result: 'success',
    },
    {
      id: 'audit-request-assigned',
      actorUserId: 'admin-uid-001',
      actorRole: 'admin',
      action: 'REQUEST_ASSIGNED',
      targetType: 'request',
      targetId: 'request-doc-002',
      oldValue: { status: 'created', agentId: null },
      newValue: { status: 'assigned', agentId: 'agent-uid-001' },
      result: 'success',
    },
    {
      id: 'audit-request-updated',
      actorUserId: 'agent-uid-001',
      actorRole: 'agent',
      action: 'REQUEST_UPDATED',
      targetType: 'request',
      targetId: 'request-doc-004',
      oldValue: { status: 'accepted' },
      newValue: { status: 'in_progress' },
      result: 'success',
    },
    {
      id: 'audit-authorization-failed',
      actorUserId: 'customer-uid-001',
      actorRole: 'customer',
      action: 'AUTHORIZATION_FAILED',
      targetType: 'request',
      targetId: 'request-doc-006',
      oldValue: {},
      newValue: {},
      result: 'denied',
    },
    {
      id: 'audit-database-error',
      actorUserId: 'admin-uid-001',
      actorRole: 'admin',
      action: 'DATABASE_ERROR',
      targetType: 'database',
      targetId: 'requests',
      oldValue: {},
      newValue: {},
      result: 'failure',
    },
  ];

  const timestamp = Timestamp.now();

  for (const log of auditLogs) {
    await db.collection('audit_logs').doc(log.id).set(
      {
        actorUserId: log.actorUserId,
        actorRole: log.actorRole,
        action: log.action,
        targetType: log.targetType,
        targetId: log.targetId,
        oldValue: log.oldValue,
        newValue: log.newValue,
        result: log.result,
        timestamp,
      },
      { merge: true },
    );
  }

  console.log('Seeded 6 audit logs.');
}

async function seedCounters() {
  await db.collection('counters').doc('2026').set(
    {
      lastRequestNumber: 7,
    },
    { merge: true },
  );

  console.log('Seeded counter counters/2026.');
}

async function main() {
  await seedUsers();
  await seedServices();
  await seedRequests();
  await seedStatusHistory();
  await seedAuditLogs();
  await seedCounters();
  console.log('QuickServe Emulator seed completed successfully.');
}

main().catch((error) => {
  console.error(`QuickServe Emulator seed failed: ${error.message}`);
  process.exitCode = 1;
});
