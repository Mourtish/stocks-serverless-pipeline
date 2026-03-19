import boto3
import json
import os
from datetime import datetime, timedelta
from decimal import Decimal

DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE")
REGION = os.getenv("AWS_REGION", "us-east-1")

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(DYNAMODB_TABLE)


def decimal_default(obj):
    """Helper to serialize Decimal objects to float for JSON"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError


def lambda_handler(event, context):
    """
    Retrieve the last 7 days of biggest stock movers from DynamoDB.
    Returns: GET /movers -> List of daily movers with date, ticker, % change, and close price.
    """
    try:
        print(f"[DEBUG] API called. Path: {event.get('rawPath')}")
        print(f"[DEBUG] DynamoDB Table: {DYNAMODB_TABLE}")
        
        # Scan the DynamoDB table for all items
        # Note: In production, you'd use Query for better performance (partition key)
        response = table.scan()
        items = response.get("Items", [])
        
        print(f"[DEBUG] Retrieved {len(items)} items from DynamoDB")
        
        if not items:
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"movers": [], "count": 0})
            }
        
        # Sort by date (most recent first) and limit to 7 days
        items_sorted = sorted(items, key=lambda x: x.get("date", ""), reverse=True)[:7]
        
        # Format response
        movers = []
        for item in items_sorted:
            movers.append({
                "date": item["date"],
                "ticker": item["ticker"],
                "pct_change": float(item["pct_change"]),
                "close_price": float(item["close_price"])
            })
        
        print(f"[DEBUG] Returning {len(movers)} movers")
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"movers": movers, "count": len(movers)})
        }
    
    except Exception as e:
        print(f"[ERROR] Exception: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }
