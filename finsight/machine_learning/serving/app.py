from datetime import date
from typing import Optional

import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from .predict import get_overspend_warning

app = FastAPI(title="Overspend Risk Service", version="1.0.0")


class Transaction(BaseModel):
    transDate: date
    transAmt: float


class BudgetInput(BaseModel):
    budgetLimit: float
    budgetStartDate: date
    budgetEndDate: date
    budgetFreq: str = Field(description="weekly | biweekly | monthly")
    budgetName: str


class RiskRequest(BaseModel):
    id: Optional[str] = None
    budget: BudgetInput
    transactions: list[Transaction] = []
    today: Optional[date] = None


class RiskResponse(BaseModel):
    riskScore: float
    riskLevel: str
    projectedSpend: float
    projectedOverage: float
    shouldNotify: bool


class BatchRiskRequest(BaseModel):
    items: list[RiskRequest]


class BatchRiskItem(RiskResponse):
    id: Optional[str] = None
    error: Optional[str] = None


class BatchRiskResponse(BaseModel):
    results: list[BatchRiskItem]


def _score_one(item: RiskRequest) -> dict:
    budget_row = {
        "budgetLimit": item.budget.budgetLimit,
        "budgetStartDate": pd.Timestamp(item.budget.budgetStartDate),
        "budgetEndDate": pd.Timestamp(item.budget.budgetEndDate),
        "budgetFreq": item.budget.budgetFreq,
        "budgetName": item.budget.budgetName,
    }

    if item.transactions:
        txns = pd.DataFrame(
            {
                "transDate": [pd.Timestamp(t.transDate) for t in item.transactions],
                "transAmt": [t.transAmt for t in item.transactions],
            }
        )
    else:
        txns = pd.DataFrame({"transDate": pd.Series(dtype="datetime64[ns]"), "transAmt": pd.Series(dtype="float")})

    today = pd.Timestamp(item.today) if item.today else pd.Timestamp.now().normalize()

    return get_overspend_warning(budget_row, txns, today)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict/overspend-risk", response_model=RiskResponse)
def predict_overspend_risk(payload: RiskRequest):
    try:
        return _score_one(payload)
    except Exception as exc:  # noqa: BLE001 - surface as a clean 400 to the caller
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.post("/predict/overspend-risk/batch", response_model=BatchRiskResponse)
def predict_overspend_risk_batch(payload: BatchRiskRequest):
    results: list[dict] = []
    for idx, item in enumerate(payload.items):
        try:
            result = _score_one(item)
            result["id"] = item.id
        except Exception as exc:  # noqa: BLE001 - one bad budget shouldn't fail the batch
            result = {
                "riskScore": 0.0,
                "riskLevel": "Low",
                "projectedSpend": 0.0,
                "projectedOverage": 0.0,
                "shouldNotify": False,
                "id": item.id,
                "error": str(exc),
            }
        results.append(result)
    return {"results": results}
