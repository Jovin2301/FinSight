const db = require('../database');
const { v4: uuidv4 } = require('uuid');

function categoryNameForDb(category) {
    if (category === 'Food') return 'Food & Dining';
    if (category === 'Bills') return 'Utilities';
    if (category === 'Shopping' || category === 'Others') return 'Entertainment';
    return category;
}

async function getCategoryId(category) {
    const result = await db.query(
        `SELECT "catID"
        FROM public."transactionCategory"
        WHERE LOWER("catName") = LOWER($1)
            AND LOWER("catType") = 'expense'
        LIMIT 1`,
        [categoryNameForDb(category)]
    );

    if (!result.rows[0]) throw new Error('Category not found');
    return result.rows[0].catID;
}

async function getTransactions(userId) {
    const result = await db.query(
        `SELECT
            t."transID" AS id,
            t."transDesc" AS title,
            CASE
                WHEN c."catName" = 'Food & Dining' THEN 'Food'
                WHEN c."catName" = 'Utilities' THEN 'Bills'
                WHEN c."catName" = 'Entertainment' THEN 'Shopping'
                ELSE c."catName"
            END AS category,
            t."transAmt" AS amount,
            TO_CHAR(t."transDate", 'YYYY-MM-DD') AS date,
            t."transPaymentMethod" AS "paymentMethod"
        FROM public."transactionHistory" t
        JOIN public."transactionCategory" c ON t."catID" = c."catID"
        WHERE t."userID" = $1 AND LOWER(c."catType") = 'expense'
        ORDER BY t."transDate" DESC, t."createdAt" DESC`,
        [userId]
    );

    return result.rows;
}

async function createTransaction(userId, transaction) {
    const catId = await getCategoryId(transaction.category);

    await db.query(
        `INSERT INTO public."transactionHistory"
        ("transID", "userID", "catID", "transAmt", "transDate",
        "createdAt", "updatedAt", "transDesc", "transPaymentMethod")
        VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $6, $7)`,
        [
            uuidv4(),
            userId,
            catId,
            transaction.amount,
            transaction.date,
            transaction.title,
            transaction.paymentMethod || 'Cash'
        ]
    );
}

async function updateTransaction(userId, transactionId, transaction) {
    const catId = await getCategoryId(transaction.category);

    await db.query(
        `UPDATE public."transactionHistory"
        SET "catID" = $1,
            "transAmt" = $2,
            "transDate" = $3,
            "updatedAt" = CURRENT_TIMESTAMP,
            "transDesc" = $4,
            "transPaymentMethod" = $5
        WHERE "transID" = $6 AND "userID" = $7`,
        [
            catId,
            transaction.amount,
            transaction.date,
            transaction.title,
            transaction.paymentMethod || 'Cash',
            transactionId,
            userId
        ]
    );
}

async function deleteTransaction(userId, transactionId) {
    await db.query(
        `DELETE FROM public."transactionHistory"
        WHERE "transID" = $1 AND "userID" = $2`,
        [transactionId, userId]
    );
}

async function getTransactionsForBudget(userId, catId, startDate) {
    const result = await db.query(
        `SELECT
            t."transDate" AS "transDate",
            t."transAmt" AS "transAmt"
        FROM public."transactionHistory" t
        WHERE t."userID" = $1
            AND t."catID" = $2
            AND t."transDate" >= $3
        ORDER BY t."transDate" ASC`,
        [userId, catId, startDate]
    );

    return result.rows;
}

module.exports = {
    getTransactions,
    createTransaction,
    updateTransaction,
    deleteTransaction,
    getTransactionsForBudget
};
