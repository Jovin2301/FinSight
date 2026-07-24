const db = require('../database');
const { v4: uuidv4 } = require('uuid');
const notificationService = require('./notificationService');

// get categories to show in budget form
async function getCategories() {
    return [
        { name: 'Food' },
        { name: 'Transport' },
        { name: 'Shopping' },
        { name: 'Bills' },
        { name: 'Others' }
    ];
}

// budget stores catID, so need to find it from category name
async function getCategoryId(categoryName) {
    const dbCategory = categoryNameForDb(categoryName);
    const result = await db.query(
        `SELECT "catID"
        FROM public."transactionCategory"
        WHERE LOWER("catName") = LOWER($1)
        LIMIT 1`,
        [dbCategory]
    );

    if (!result.rows[0]) {
        throw new Error('Category not found');
    }

    return result.rows[0].catID;
}

// get all budgets for one user
async function getBudgets(userId) {
    const result = await db.query(
        `SELECT
            b."budgetID" AS id,
            b."catID" AS "catId",
            b."budgetName" AS name,
            b."budgetDesc" AS description,
            b."budgetLimit" AS "limit",
            b."budgetFreq" AS frequency,
            b."budgetStartDate" AS "startDate",
            b."budgetEndDate" AS "endDate",
            CASE
                WHEN c."catName" = 'Food & Dining' THEN 'Food'
                WHEN c."catName" = 'Utilities' THEN 'Bills'
                WHEN c."catName" = 'Entertainment' THEN 'Others'
                ELSE c."catName"
            END AS category,
            COALESCE(SUM(t."transAmt"), 0) AS spent
        FROM public."Budget" b
        JOIN public."transactionCategory" c
            ON b."catID" = c."catID"
        LEFT JOIN public."transactionHistory" t
            ON t."userID" = b."userID"
            AND t."catID" = b."catID"
            AND t."transDate" BETWEEN b."budgetStartDate" AND b."budgetEndDate"
        WHERE b."userID" = $1
        GROUP BY b."budgetID", c."catName"
        ORDER BY b."budgetStartDate" DESC, b."budgetName"`,
        [userId]
    );

    const budgets = result.rows.map((budget) => {
        const parts = (budget.description || '').split('|');
        if (parts.length > 1) {
            budget.icon = parts[0];
            budget.description = parts.slice(1).join('|');
        } else {
            budget.icon = iconForCategory(budget.category);
        }

        return budget;
    });

    await notificationService.createBudgetWarnings(userId, budgets);
    return budgets;
}

// create new budget
async function createBudget(userId, budget) {
    const catId = await getCategoryId(budget.category);
    const startDate = budget.startDate || new Date().toISOString().split('T')[0];
    const endDate = budget.endDate || startDate;
    const description = `${budget.icon || iconForCategory(budget.category)}|${budget.description || ''}`;

    const result = await db.query(
        `INSERT INTO public."Budget"
        ("budgetID", "userID", "catID", "budgetStartDate", "budgetEndDate",
        "budgetLimit", "budgetName", "budgetDesc", "budgetFreq")
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING "budgetID" AS id`,
        [
            uuidv4(),
            userId,
            catId,
            startDate,
            endDate,
            budget.limit,
            budget.name,
            description,
            budget.frequency || 'monthly'
        ]
    );

    return result.rows[0];
}

// edit existing budget
async function updateBudget(userId, budgetId, budget) {
    const catId = await getCategoryId(budget.category);
    const description = `${budget.icon || iconForCategory(budget.category)}|${budget.description || ''}`;

    await db.query(
        `UPDATE public."Budget"
        SET "catID" = $1,
            "budgetLimit" = $2,
            "budgetName" = $3,
            "budgetDesc" = $4,
            "budgetFreq" = $5,
            "budgetStartDate" = $6,
            "budgetEndDate" = $7
        WHERE "budgetID" = $8 AND "userID" = $9`,
        [
            catId,
            budget.limit,
            budget.name,
            description,
            budget.frequency || 'monthly',
            budget.startDate,
            budget.endDate,
            budgetId,
            userId
        ]
    );
}

// delete budget
async function deleteBudget(userId, budgetId) {
    await db.query(
        `DELETE FROM public."Budget"
        WHERE "budgetID" = $1 AND "userID" = $2`,
        [budgetId, userId]
    );
}

function iconForCategory(category) {
    const lower = category.toLowerCase();
    if (lower.includes('food')) return '🍔';
    if (lower.includes('transport')) return '🚌';
    if (lower.includes('entertainment')) return '🎬';
    if (lower.includes('util')) return '💡';
    if (lower.includes('shop')) return '🛍️';
    return '💰';
}

function categoryNameForDb(categoryName) {
    if (categoryName === 'Food') return 'Food & Dining';
    if (categoryName === 'Bills') return 'Utilities';
    if (categoryName === 'Shopping') return 'Entertainment';
    if (categoryName === 'Others') return 'Entertainment';
    return categoryName;
}

module.exports = {
    getCategories,
    getBudgets,
    createBudget,
    updateBudget,
    deleteBudget
};
