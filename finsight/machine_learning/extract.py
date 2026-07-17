# loading the required data from supabase
import os
from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.environ["SUPABASE_DB_URL"]

RAW_DIR = Path(__file__).resolve().parent / "data" / "raw_data"
RAW_DIR.mkdir(parents=True, exist_ok=True)

def extract():
    engine = create_engine(DB_URL)
 
    print("Extracting budgets...")
    budgets = pd.read_sql(
        """
        SELECT * FROM public."Budget"
        """,
        engine,
    )
    budgets.to_csv(RAW_DIR / "budgets.csv", index=False)
    print(f"  -> {len(budgets)} rows saved to {RAW_DIR / 'budgets.csv'}")
 
    print("Extracting transactions...")
    transactions = pd.read_sql(
        """
        SELECT * FROM public."transactionHistory"
        """,
        engine,
    )
    transactions.to_csv(RAW_DIR / "transactions.csv", index=False)
    print(f"  -> {len(transactions)} rows saved to {RAW_DIR / 'transactions.csv'}")

    print("Extracting category...")
    transactions = pd.read_sql(
        """
        SELECT * FROM public."transactionCategory"
        """,
        engine,
    )
    transactions.to_csv(RAW_DIR / "transactionsCat.csv", index=False)
    print(f"  -> {len(transactions)} rows saved to {RAW_DIR / 'transactionsCat.csv'}")
    
 
    engine.dispose()
    print("\nExtraction complete.")
 
 
if __name__ == "__main__":
    extract()