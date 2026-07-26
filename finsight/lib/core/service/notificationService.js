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

/*async function createBudgetWarnings(userId, budgets) {
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
}*/

/*async function createBudgetWarnings(userId, budgets) {
    const today = new Date().toISOString().split('T')[0];

    const activeBudgets = budgets.filter((budget) => {
        const startDate = new Date(budget.startDate).toISOString().split('T')[0];
        const endDate = new Date(budget.endDate).toISOString().split('T')[0];
        return today >= startDate && today <= endDate;
    });

    if (!activeBudgets.length) return;

    // Pull transactions and score every active budget's overspend risk in one round trip.
    const scoringInputs = await Promise.all(
        activeBudgets.map(async (budget) => ({
            budget,
            transactions: await getTransactionsForBudget(userId, budget.catId, budget.startDate),
        }))
    );
    const riskById = await mlRiskService.getOverspendRiskBatch(scoringInputs, today);

    for (const budget of activeBudgets) {
        const limit = Number(budget.limit);
        const spent = Number(budget.spent);
        const category = budget.category.toLowerCase();
        const risk = riskById.get(budget.id);

        let message = null;

        if (risk) {
            // Model available: notify on genuine projected-overage risk, not just
            // "80% spent" (e.g. a budget that's 90% spent but almost over its
            // window with a low daily burn rate is lower risk than the flat rule assumes).
            if (risk.shouldNotify) {
                message =
                    risk.riskLevel === 'High'
                        ? `Your ${category} budget is on track to go over by ~$${risk.projectedOverage.toFixed(2)}. Consider slowing spending.`
                        : `Heads up: your ${category} budget may run over this period (projected overage ~$${risk.projectedOverage.toFixed(2)}).`;
            }
        } else if (limit > 0 && spent / limit >= 0.8) {
            // Fallback: model service was unreachable/errored for this budget.
            message = `You have used 80% of your ${category} budget.`;
        }

        if (!message) continue;

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
}*/
async function createBudgetWarnings(userId, budgets) {
    const today = new Date().toISOString().split('T')[0];
 
    const activeBudgets = budgets.filter((budget) => {
        const startDate = new Date(budget.startDate).toISOString().split('T')[0];
        const endDate = new Date(budget.endDate).toISOString().split('T')[0];
        return today >= startDate && today <= endDate;
    });
 
    console.log(`[budgetWarnings] today=${today} totalBudgets=${budgets.length} activeBudgets=${activeBudgets.length}`);
    if (!activeBudgets.length) return;
 
    // Pull transactions and score every active budget's overspend risk in one round trip.
    const scoringInputs = await Promise.all(
        activeBudgets.map(async (budget) => ({
            budget,
            transactions: await getTransactionsForBudget(userId, budget.catId, budget.startDate),
        }))
    );
    console.log(`[budgetWarnings] ML_SERVICE_URL=${process.env.ML_SERVICE_URL || '(unset, using localhost fallback!)'}`);
    const riskById = await mlRiskService.getOverspendRiskBatch(scoringInputs, today);
    console.log(`[budgetWarnings] riskById size=${riskById.size}`, [...riskById.entries()]);
 
    for (const budget of activeBudgets) {
        const limit = Number(budget.limit);
        const spent = Number(budget.spent);
        const category = budget.category.toLowerCase();
        const risk = riskById.get(budget.id);
 
        let message = null;
 
        if (risk) {
            // Model available: notify on genuine projected-overage risk, not just
            // "80% spent" (e.g. a budget that's 90% spent but almost over its
            // window with a low daily burn rate is lower risk than the flat rule assumes).
            if (risk.shouldNotify) {
                const riskPercent = Math.round(risk.riskScore * 100);
                message = `Continue spending at this rate, there is a ${riskPercent}% chance of you overspending for your ${category} budget.`;
            }
        } else if (limit > 0 && spent / limit >= 0.8) {
            // Fallback: model service was unreachable/errored for this budget.
            message = `You have used 80% of your ${category} budget.`;
        }
 
        if (!message) continue;
 
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
