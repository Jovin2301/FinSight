"""
Builds the exact feature row the model expects, for a budget that is
currently in progress (i.e. "as of today", not a historical snapshot).

This mirrors the feature engineering in models/train_model.ipynb.
If you ever change a feature there, mirror the change here too — the two
must stay in lockstep or predictions will silently be wrong.
"""

from pathlib import Path

import joblib
import pandas as pd

MODELS_DIR = Path(__file__).resolve().parent.parent / "models"

BUDGET_FREQS = ["weekly", "biweekly", "monthly"]
BUDGET_NAMES = ["Entertainment", "Food", "Transport", "Utilities"]

# Same mapping used in training to collapse messy budgetName variants
BUDGET_NAME_MAP = {
    "Food & Dining Budget": "Food",
    "Food Budget": "Food",
    "Food": "Food",
    "Transport Budget": "Transport",
    "Transport": "Transport",
    "Utilities Budget": "Utilities",
    "Bills": "Utilities",
    "Entertainment Budget": "Entertainment",
    "Entertainment": "Entertainment",
}


def load_feature_columns(models_dir: Path = MODELS_DIR) -> list[str]:
    """The exact column order the model was trained on."""
    return joblib.load(models_dir / "model_feature_columns.pkl")


def compute_live_features(
    budget_row: dict,
    transactions_so_far: pd.DataFrame,
    today: pd.Timestamp,
    feature_columns: list[str],
) -> pd.DataFrame:
    """
    Compute a single-row feature DataFrame for one in-progress budget, "as of" `today`.

    Parameters
    ----------
    budget_row : dict-like with keys
        budgetLimit, budgetStartDate, budgetEndDate, budgetFreq, budgetName
        (budgetStartDate / budgetEndDate should already be pd.Timestamp)
    transactions_so_far : DataFrame
        Transactions for this budget's user + category. Must have
        columns 'transDate' (Timestamp) and 'transAmt' (float).
        Does not need to be pre-filtered to `today` — this function filters.
    today : pd.Timestamp
        The "as of" date to compute features for (usually pd.Timestamp.now()).
    feature_columns : list[str]
        Output of load_feature_columns() — enforces training-time column order.

    Returns
    -------
    pd.DataFrame with exactly one row, columns matching feature_columns.
    """
    start = budget_row["budgetStartDate"]
    end = budget_row["budgetEndDate"]
    budget_limit = float(budget_row["budgetLimit"])

    txns = transactions_so_far[transactions_so_far["transDate"] <= today]

    total_spent = float(txns["transAmt"].sum())
    num_transactions = int(len(txns))
    avg_transaction = float(txns["transAmt"].mean()) if num_transactions > 0 else 0.0
    max_transaction = float(txns["transAmt"].max()) if num_transactions > 0 else 0.0
    std_transaction = float(txns["transAmt"].std()) if num_transactions > 1 else 0.0

    days_elapsed = (today - start).days + 1
    budget_duration = (end - start).days + 1
    days_remaining = (end - today).days

    row = {
        "budgetLimit": budget_limit,
        "daysElapsed": days_elapsed,
        "daysRemaining": days_remaining,
        "budgetDuration": budget_duration,
        "totalSpent": total_spent,
        "numTransactions": num_transactions,
        "avgTransaction": avg_transaction,
        "maxTransaction": max_transaction,
        "stdTransaction": std_transaction,
        "budgetUtilization": total_spent / budget_limit if budget_limit else 0.0,
        "remainingBudget": budget_limit - total_spent,
    }

    # One-hot encode budgetFreq the same way OneHotEncoder did in training
    for freq in BUDGET_FREQS:
        row[f"budgetFreq_{freq}"] = 1.0 if budget_row["budgetFreq"] == freq else 0.0

    # Normalize + one-hot encode budgetName the same way training did
    normalized_name = BUDGET_NAME_MAP.get(budget_row["budgetName"], budget_row["budgetName"])
    for name in BUDGET_NAMES:
        row[f"budgetName_{name}"] = 1.0 if normalized_name == name else 0.0

    df = pd.DataFrame([row])

    # Reindex to the exact training column order; anything unexpected becomes 0
    return df.reindex(columns=feature_columns, fill_value=0.0)