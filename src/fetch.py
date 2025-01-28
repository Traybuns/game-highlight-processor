import json

# Import the 'boto3' library for interacting with AWS services like S3
import boto3

# Import the 'requests' library for making HTTP requests to external APIs
import requests

# Import specific configuration variables from the 'config.py' module
from config import (
    API_URL,             
    RAPIDAPI_HOST,       
    RAPIDAPI_KEY,        
    DATE,                
    LEAGUE_NAME,         
    LIMIT,               
    S3_BUCKET_NAME,      
    AWS_REGION,          
)

def fetch_highlights():
    try:
       
        query_params = {
            "date": DATE,           
            "leagueName": LEAGUE_NAME,  
            "limit": LIMIT            
        }
        
        
        headers = {
            "X-RapidAPI-Key": RAPIDAPI_KEY,      
            "X-RapidAPI-Host": RAPIDAPI_HOST     
        }

        response = requests.get(API_URL, headers=headers, params=query_params, timeout=120)

        response.raise_for_status()
        
        
        highlights = response.json()
        
        
        print("Highlights fetched successfully!")
        
     
        return highlights

    except requests.exceptions.RequestException as e:
       
        print(f"Error fetching highlights: {e}")
        
        
        return None

def save_to_s3(data, file_name):
    try:
       
        s3 = boto3.client("s3", region_name=AWS_REGION)

       
        try:
            s3.head_bucket(Bucket=S3_BUCKET_NAME)
           
            print(f"Bucket {S3_BUCKET_NAME} exists.")
        except Exception:
           
            print(f"Bucket {S3_BUCKET_NAME} does not exist. Creating...")
            if AWS_REGION == "us-east-1":
                
                s3.create_bucket(Bucket=S3_BUCKET_NAME)
            else:
                
                s3.create_bucket(
                    Bucket=S3_BUCKET_NAME,
                    CreateBucketConfiguration={"LocationConstraint": AWS_REGION}
                )
            
            print(f"Bucket {S3_BUCKET_NAME} created successfully.")

        
        s3_key = f"highlights/{file_name}.json"

        
        s3.put_object(
            Bucket=S3_BUCKET_NAME,                   
            Key=s3_key,                                
            Body=json.dumps(data),                      
            ContentType="application/json"             
        )
        

        print(f"Highlights saved to S3: s3://{S3_BUCKET_NAME}/{s3_key}")
    
    except Exception as e:
        
        print(f"Error saving to S3: {e}")

def process_highlights():
    highlights = fetch_highlights()
    
    
    if highlights:
        
        print("Saving highlights to S3...")
        
        
        save_to_s3(highlights, "basketball_highlights")


if __name__ == "__main__":
    process_highlights()