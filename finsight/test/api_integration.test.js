process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

const test = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = require('../server');
const db = require('../lib/core/database');
const budgetService = require('../lib/core/service/budgetService');
const transactionService = require('../lib/core/service/transactionService');
const notificationService = require('../lib/core/service/notificationService');
const recurringService = require('../lib/core/service/recurringService');

let server;
let baseUrl;

const oldDbQuery = db.query;
const oldBudget = {
    getBudgets: budgetService.getBudgets,
    createBudget: budgetService.createBudget,
};
const oldTransaction = {
    getTransactions: transactionService.getTransactions,
    createTransaction: transactionService.createTransaction,
};
const oldNotification = {
    getNotifications: notificationService.getNotifications,
};
const oldRecurring = {
    getRecurringPayments: recurringService.getRecurringPayments,
    createRecurringPayment: recurringService.createRecurringPayment,
};

function authHeaders() {
    const token = jwt.sign({ userId: 'test-user-1' }, process.env.JWT_SECRET);
    return {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
    };
}

test.before(async () => {
    server = app.listen(0, '127.0.0.1');
    await new Promise((resolve) => server.once('listening', resolve));
    const { port } = server.address();
    baseUrl = `http://127.0.0.1:${port}`;
});

test.after(async () => {
    db.query = oldDbQuery;
    Object.assign(budgetService, oldBudget);
    Object.assign(transactionService, oldTransaction);
    Object.assign(notificationService, oldNotification);
    Object.assign(recurringService, oldRecurring);
    await new Promise((resolve) => server.close(resolve));
});

test('login returns jwt token and user details', async () => {
    const hashedPassword = await bcrypt.hash('123456', 4);
    db.query = async () => ({
        rows: [
            {
                userID: 'test-user-1',
                userName: 'Test User',
                userEmail: 'test@example.com',
                userPassword: hashedPassword,
            },
        ],
    });

    const response = await fetch(`${baseUrl}/user/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email: 'test@example.com',
            password: '123456',
        }),
    });

    const body = await response.json();

    assert.equal(response.status, 200);
    assert.ok(body.token);
    assert.equal(body.user.id, 'test-user-1');
    assert.equal(body.user.email, 'test@example.com');
});

test('budget route saves budget and returns updated budget list', async () => {
    let createdBudget;

    budgetService.createBudget = async (userId, budget) => {
        createdBudget = { userId, ...budget };
    };
    budgetService.getBudgets = async () => [
        {
            id: 'budget-1',
            category: createdBudget.category,
            limit: createdBudget.limit,
            frequency: createdBudget.frequency,
        },
    ];

    const response = await fetch(`${baseUrl}/budget`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({
            category: 'Food',
            limit: 300,
            frequency: 'monthly',
        }),
    });

    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(createdBudget.userId, 'test-user-1');
    assert.equal(body[0].category, 'Food');
    assert.equal(body[0].limit, 300);
});

test('transaction route saves transaction and returns transaction history', async () => {
    let createdTransaction;

    transactionService.createTransaction = async (userId, transaction) => {
        createdTransaction = { userId, ...transaction };
    };
    transactionService.getTransactions = async () => [
        {
            id: 'transaction-1',
            title: createdTransaction.title,
            amount: createdTransaction.amount,
            category: createdTransaction.category,
        },
    ];
    budgetService.getBudgets = async () => [];

    const response = await fetch(`${baseUrl}/transaction`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({
            title: 'Lunch',
            amount: 8.5,
            category: 'Food',
        }),
    });

    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(createdTransaction.userId, 'test-user-1');
    assert.equal(body[0].title, 'Lunch');
    assert.equal(body[0].amount, 8.5);
});

test('notification route returns budget notifications', async () => {
    notificationService.getNotifications = async (userId) => [
        {
            id: 'notification-1',
            userId,
            type: 'budget',
            message: 'You have used 80% of your Food budget.',
            isRead: false,
        },
    ];

    const response = await fetch(`${baseUrl}/notification`, {
        headers: authHeaders(),
    });

    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body[0].type, 'budget');
    assert.equal(body[0].isRead, false);
});

test('recurring route saves bill or subscription', async () => {
    let createdRecurringPayment;

    recurringService.createRecurringPayment = async (userId, recurringPayment) => {
        createdRecurringPayment = { userId, ...recurringPayment };
    };
    recurringService.getRecurringPayments = async () => [
        {
            id: 'recurring-1',
            name: createdRecurringPayment.name,
            amount: createdRecurringPayment.amount,
            frequency: createdRecurringPayment.frequency,
        },
    ];

    const response = await fetch(`${baseUrl}/recurring`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({
            name: 'Netflix Subscription',
            amount: 15.98,
            frequency: 'monthly',
            category: 'Bills',
        }),
    });

    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(createdRecurringPayment.userId, 'test-user-1');
    assert.equal(body[0].name, 'Netflix Subscription');
    assert.equal(body[0].frequency, 'monthly');
});
