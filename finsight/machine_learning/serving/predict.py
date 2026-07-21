"""
Loads the trained, calibrated model once and exposes get_overspend_warning(),
the function your app's API/cron job should call for each active budget.

Usage:
    from serving.predict import get_overspend_warning

    warning = get_overspend_warning(budget_row, transactions_so_far, today)
"""

from functools import lru_cache
from pathlib import Path

import joblib
import pandas as pd

from .feature_builder import compute_live_features, load_feature_columns

MODELS_DIR = Path(__file__).resolve().parent.parent / "models"

RISK_HIGH = 0.6
RISK_MEDIUM = 0.3


@lru_cache(maxsize=1)
def _load_model():
    """Loaded once per process and cached — retraining/reloading happens out of band."""
    model = joblib.load(MODELS_DIR / "overspend_risk_model.pkl")
    feature_columns = load_feature_columns(MODELS_DIR)
    return model, feature_columns


def risk_level(risk_score: float) -> str:
    if risk_score >= RISK_HIGH:
        return "High"
    if risk_score >= RISK_MEDIUM:
        return "Medium"
    return "Low"


def get_overspend_warning(
    budget_row: dict,
    transactions_so_far: pd.DataFrame,
    today: pd.Timestamp | None = None,
) -> dict:
    """
    Compute a risk score + projected spend for one in-progress budget.

    Parameters
    ----------
    budget_row : dict-like with keys
        budgetLimit, budgetStartDate, budgetEndDate, budgetFreq, budgetName
        (budgetStartDate / budgetEndDate as pd.Timestamp)
    transactions_so_far : DataFrame
        Transactions for this budget's user + category, columns 'transDate', 'transAmt'.
    today : pd.Timestamp, optional
        Defaults to now. Pass an explicit date for backtesting / testing.

    Returns
    -------
    dict with riskScore, riskLevel, projectedSpend, projectedOverage, shouldNotify
    """
    if today is None:
        today = pd.Timestamp.now().normalize()

    model, feature_columns = _load_model()

    X_live = compute_live_features(budget_row, transactions_so_far, today, feature_columns)
    risk_score = float(model.predict_proba(X_live)[0, 1])

    total_spent = float(X_live["totalSpent"].iloc[0])
    days_elapsed = int(X_live["daysElapsed"].iloc[0])
    budget_duration = int(X_live["budgetDuration"].iloc[0])
    budget_limit = float(budget_row["budgetLimit"])

    daily_rate = total_spent / days_elapsed if days_elapsed > 0 else 0.0
    projected_spend = daily_rate * budget_duration
    projected_overage = projected_spend - budget_limit

    return {
        "riskScore": round(risk_score, 3),
        "riskLevel": risk_level(risk_score),
        "projectedSpend": round(projected_spend, 2),
        "projectedOverage": round(projected_overage, 2),
        "shouldNotify": risk_score >= RISK_HIGH and projected_overage > 0,
    }


if __name__ == "__main__":
    # Quick manual smoke test — adjust dates/amounts to something in your data
    # before relying on this; it's not a substitute for testing against
    # real historical budgets with known outcomes.
    sample_budget = {
        "budgetLimit": 200.0,
        "budgetStartDate": pd.Timestamp("2026-07-01"),
        "budgetEndDate": pd.Timestamp("2026-07-30"),
        "budgetFreq": "monthly",
        "budgetName": "Food",
    }
    sample_transactions = pd.DataFrame({
        "transDate": pd.to_datetime([
            "2026-07-02", "2026-07-04", "2026-07-07", "2026-07-10", "2026-07-12",
        ]),
        "transAmt": [25.0, 18.5, 40.0, 22.0, 30.0],
    })

    result = get_overspend_warning(
        sample_budget,
        sample_transactions,
        today=pd.Timestamp.now(),
    )
    print(result)