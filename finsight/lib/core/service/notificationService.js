const db = require('../database');
const { v4: uuidv4 } = require('uuid');
const mlRiskService = require('./mlRiskService');
const { getTransactionsForBudget } = require('./transactionService');

async function getNotifications(userId) {
    const result = await db.query(
        `SELECT
            "nID" AS id,
            "nType" AS type,
            "nMessage" AS message,
            "nDate" AS date,
            "isRead" AS "isRead"
        FROM public."Notification"
        WHERE "userID" = $1
        ORDER BY "nDate" DESC`,
        [userId]
    );

    return result.rows;
}

async function markAsRead(userId, notificationId) {
    await db.query(
        `UPDATE public."Notification"
        SET "isRead" = true
        WHERE "nID" = $1 AND "userID" = $2`,
        [notificationId, userId]
    );
}

async function markAllAsRead(userId) {
    await db.query(
        `UPDATE public."Notification"
        SET "isRead" = true
        WHERE "userID" = $1`,
        [userId]
    );
}

async function createBudgetWarnings(userId, budgets) {
    const today = new Date().toISOString().split('T')[0];

    for (const budget of budgets) {
        const limit = Number(budget.limit);
        const spent = Number(budget.spent);
        const startDate = new Date(budget.startDate).toISOString().split('T')[0];
        const endDate = new Date(budget.endDate).toISOString().split('T')[0];

        if (today < startDate || today > endDate) continue;
        if (limit <= 0 || spent / limit < 0.8) continue;

        const category = budget.category.toLowerCase();
        const message = `You have used 80% of your ${category} budget.`;

        const existing = await db.query(
            `SELECT "nID"
            FROM public."Notification"
            WHERE "userID" = $1
                AND "nType" = 'budget'
                AND "nMessage" = $2
                AND "nDate" BETWEEN $3 AND $4
            LIMIT 1`,
            [userId, message, budget.startDate, budget.endDate]
        );

        if (existing.rows.length > 0) continue;

        await db.query(
            `INSERT INTO public."Notification"
            ("nID", "userID", "nType", "nMessage", "nDate", "isRead")
            VALUES ($1, $2, 'budget', $3, CURRENT_DATE, false)`,
            [uuidv4(), userId, message]
        );
    }
}

module.exports = {
    getNotifications,
    markAsRead,
    markAllAsRead,
    createBudgetWarnings
};
