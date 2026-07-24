const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:8000';
const REQUEST_TIMEOUT_MS = Number(process.env.ML_SERVICE_TIMEOUT_MS) || 8000;

function toISODate(value) {
    if (!value) return null;
    const d = value instanceof Date ? value : new Date(value);
    return d.toISOString().split('T')[0];
}

// budget: { id, limit, startDate, endDate, frequency, name }
// transactions: [{ transDate, transAmt }]
function buildRiskRequestItem(budget, transactions, today) {
    return {
        id: budget.id,
        budget: {
            budgetLimit: Number(budget.limit),
            budgetStartDate: toISODate(budget.startDate),
            budgetEndDate: toISODate(budget.endDate),
            budgetFreq: budget.frequency,
            budgetName: budget.name,
        },
        transactions: (transactions || []).map((t) => ({
            transDate: toISODate(t.transDate),
            transAmt: Number(t.transAmt),
        })),
        today: toISODate(today) || undefined,
    };
}

async function postJson(path, body) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    try {
        const res = await fetch(`${ML_SERVICE_URL}${path}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
            signal: controller.signal,
        });

        if (!res.ok) {
            const detail = await res.text().catch(() => '');
            throw new Error(`ML service ${path} returned ${res.status}: ${detail}`);
        }

        return await res.json();
    } finally {
        clearTimeout(timeout);
    }
}

// Score a single in-progress budget. Returns null (rather than throwing) on any
// failure so a down/slow model service never blocks the caller's main flow.
async function getOverspendRisk(budget, transactions, today) {
    try {
        const payload = buildRiskRequestItem(budget, transactions, today);
        return await postJson('/predict/overspend-risk', payload);
    } catch (err) {
        console.error('mlRiskService.getOverspendRisk failed:', err.message);
        return null;
    }
}

// Score many budgets in one round trip. Returns a Map keyed by budget.id.
// Budgets that fail to score (or if the whole service is unreachable) are
// simply absent from the map — callers should treat a missing entry as
// "risk unknown" and fall back accordingly.
async function getOverspendRiskBatch(budgetsWithTransactions, today) {
    const results = new Map();
    if (!budgetsWithTransactions.length) return results;

    try {
        const items = budgetsWithTransactions.map(({ budget, transactions }) =>
            buildRiskRequestItem(budget, transactions, today)
        );
        const data = await postJson('/predict/overspend-risk/batch', { items });

        for (const result of data.results) {
            if (result.error) {
                console.error(`mlRiskService batch item ${result.id} failed:`, result.error);
                continue;
            }
            results.set(result.id, result);
        }
    } catch (err) {
        console.error('mlRiskService.getOverspendRiskBatch failed:', err.message);
    }

    return results;
}

module.exports = {
    getOverspendRisk,
    getOverspendRiskBatch,
};
