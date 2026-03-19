import sys
import os
from datetime import datetime
from decimal import Decimal

# Add vendor directory to Python path BEFORE importing vendored packages
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "vendor"))

import boto3
import requests

STOCK_API_KEY = os.getenv("STOCK_API_KEY")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE")
REGION = os.getenv("AWS_REGION", "us-east-1")
dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(DYNAMODB_TABLE)

def lambda_handler(event, context):
    """
    Fetch stock data for the watchlist, calculate the biggest mover,
    and save the result to DynamoDB.
    """
    # 📝 Step 1: Define your stock watchlist
    watchlist = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA", "META", "NFLX", "UBER", "AMD"]

    try:
        print(f"[DEBUG] Starting ingestion. API Key present: {bool(STOCK_API_KEY)}")
        print(f"[DEBUG] DynamoDB Table: {DYNAMODB_TABLE}")
        print(f"[DEBUG] Region: {REGION}")
        print(f"[DEBUG] Watchlist: {watchlist}")
        
        # 📝 Step 2: Fetch/generate mock stock data
        # TODO: Replace this with your real API call once you have the right endpoint/key
        movers = []
        
        # MOCK DATA for testing (remove when using real API)
        mock_data = {
            "AAPL": {"open": 180.50, "close": 183.75, "pct_change": 1.80},
            "MSFT": {"open": 420.00, "close": 418.50, "pct_change": -0.36},
            "GOOGL": {"open": 165.00, "close": 157.50, "pct_change": -4.55},
            "AMZN": {"open": 195.00, "close": 198.30, "pct_change": 1.69},
            "TSLA": {"open": 248.00, "close": 265.50, "pct_change": 7.06},
            "NVDA": {"open": 950.00, "close": 920.75, "pct_change": -3.08},
            "META": {"open": 510.00, "close": 545.25, "pct_change": 6.91},
            "NFLX": {"open": 280.00, "close": 265.10, "pct_change": -5.32},
            "UBER": {"open": 72.00, "close": 75.50, "pct_change": 4.86},
            "AMD": {"open": 170.00, "close": 162.50, "pct_change": -4.41},
        }
        
        for ticker in watchlist:
            try:
                print(f"[DEBUG] Processing {ticker}...")
                data = mock_data.get(ticker)
                
                if not data:
                    print(f"[WARN] No data for {ticker}")
                    continue
                
                open_price = data.get("open")
                close_price = data.get("close")

                if open_price and close_price:
                    pct_change = ((close_price - open_price) / open_price) * 100
                    movers.append({"ticker": ticker, "pct_change": pct_change, "close_price": close_price})
                    print(f"[DEBUG] {ticker}: {pct_change:.2f}% change")
                else:
                    print(f"[WARN] Missing price data for {ticker}")
            except Exception as e:
                print(f"[ERROR] Exception processing {ticker}: {str(e)}")
                continue

        print(f"[DEBUG] Collected {len(movers)} stocks with data")

        # 📝 Step 3: Find the "biggest mover"
        if not movers:
            raise Exception("No valid stock data returned.")

        biggest_mover = max(movers, key=lambda x: abs(x["pct_change"]))
        print(f"[DEBUG] Biggest mover: {biggest_mover}")

        # 📝 Step 4: Save all stocks to DynamoDB with today's date
        today = datetime.now().strftime("%Y-%m-%d")
        print(f"[DEBUG] Writing {len(movers)} stocks for date {today}")
        
        for mover in movers:
            item = {
                "date": today,
                "ticker": mover["ticker"],
                "pct_change": Decimal(str(round(mover["pct_change"], 2))),
                "close_price": Decimal(str(round(mover["close_price"], 2))),
                "is_biggest_mover": mover["ticker"] == biggest_mover["ticker"]  # Mark the biggest mover
            }
            print(f"[DEBUG] Writing {mover['ticker']}: {item}")
            table.put_item(Item=item)
        
        print(f"[SUCCESS] Successfully wrote {len(movers)} stocks to DynamoDB")
        return {"statusCode": 200, "body": f"Ingested {len(movers)} stocks. Biggest mover: {biggest_mover['ticker']} ({biggest_mover['pct_change']:.2f}%)"}

    except Exception as e:
        print(f"[ERROR] Exception in lambda_handler: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return {"statusCode": 500, "body": str(e)}
#def lambda_handler(event, context):
 #   return {"statusCode": 200, "body": "ingestion placeholder"}
