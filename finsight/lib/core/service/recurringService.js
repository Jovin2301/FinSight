const db = require('../database');
const { v4: uuidv4 } = require('uuid');

async function getCategoryId(categoryName) {
    const result = await db.query(
        `SELECT "catID"
        FROM public."transactionCategory"
        WHERE LOWER("catName") = LOWER($1)
            AND LOWER("catType") = 'expense'
        LIMIT 1`,
        [categoryNameForDb(categoryName)]
    );

    if (!result.rows[0]) {
        throw new Error('Category not found');
    }

    return result.rows[0].catID;
}

async function getRecurringPayments(userId) {
    const result = await db.query(
        `SELECT
            r."recurID" AS id,
            r."recurName" AS name,
            CASE
                WHEN c."catName" = 'Food & Dining' THEN 'Food'
                WHEN c."catName" = 'Utilities' THEN 'Bills'
                WHEN c."catName" = 'Entertainment' THEN 'Others'
                ELSE c."catName"
            END AS category,
            r."recurAmt" AS amount,
            r."recurFreq" AS frequency,
            r."recurStartDate" AS "startDate",
            r."recurEndDate" AS "endDate",
            r."recurStatus" AS status
        FROM public."recurringTransaction" r
        JOIN public."transactionCategory" c
            ON r."catID" = c."catID"
        WHERE r."userID" = $1
        ORDER BY r."recurStartDate" DESC, r."recurName"`,
        [userId]
    );

    return result.rows;
}

async function createRecurringPayment(userId, payment) {
    const catId = await getCategoryId(payment.category || 'Bills');
    const startDate = payment.startDate || new Date().toISOString().split('T')[0];
    const endDate = payment.endDate || oneYearAfter(startDate);

    await db.query(
        `INSERT INTO public."recurringTransaction"
        ("recurID", "userID", "catID", "recurName", "recurAmt",
        "recurFreq", "recurStartDate", "recurEndDate", "recurStatus")
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
            uuidv4(),
            userId,
            catId,
            payment.name,
            payment.amount,
            payment.frequency || 'monthly',
            startDate,
            endDate,
            payment.status || 'active'
        ]
    );
}

async function updateRecurringPayment(userId, recurringId, payment) {
    const catId = await getCategoryId(payment.category || 'Bills');
    const startDate = payment.startDate || new Date().toISOString().split('T')[0];
    const endDate = payment.endDate || oneYearAfter(startDate);

    await db.query(
        `UPDATE public."recurringTransaction"
        SET "catID" = $1,
            "recurName" = $2,
            "recurAmt" = $3,
            "recurFreq" = $4,
            "recurStartDate" = $5,
            "recurEndDate" = $6,
            "recurStatus" = $7
        WHERE "recurID" = $8 AND "userID" = $9`,
        [
            catId,
            payment.name,
            payment.amount,
            payment.frequency || 'monthly',
            startDate,
            endDate,
            payment.status || 'active',
            recurringId,
            userId
        ]
    );
}

async function deleteRecurringPayment(userId, recurringId) {
    await db.query(
        `DELETE FROM public."recurringTransaction"
        WHERE "recurID" = $1 AND "userID" = $2`,
        [recurringId, userId]
    );
}

function oneYearAfter(startDate) {
    const date = new Date(startDate);
    date.setFullYear(date.getFullYear() + 1);
    return date.toISOString().split('T')[0];
}

function categoryNameForDb(categoryName) {
    if (categoryName === 'Food') return 'Food & Dining';
    if (categoryName === 'Bills') return 'Utilities';
    if (categoryName === 'Shopping') return 'Entertainment';
    if (categoryName === 'Others') return 'Entertainment';
    return categoryName;
}

module.exports = {
    getRecurringPayments,
    createRecurringPayment,
    updateRecurringPayment,
    deleteRecurringPayment
};
