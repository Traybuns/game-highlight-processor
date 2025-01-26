

import json


import boto3


import requests


from io import BytesIO


from config import (
    S3_BUCKET_NAME,  
    AWS_REGION,      
    INPUT_KEY,       
    OUTPUT_KEY       
)

def process_one_video():
    """
    Fetch a highlight URL from the JSON file in S3, download the video,
    and save it back to S3.
    
    This function performs the following steps:
    1. Connects to the specified S3 bucket.
    2. Retrieves the input JSON file containing video URLs.
    3. Extracts the first video URL from the JSON data.
    4. Downloads the video from the extracted URL.
    5. Uploads the downloaded video to the specified S3 location.
    """
    try:
        
        s3 = boto3.client("s3", region_name=AWS_REGION)

        
        print("Fetching JSON file from S3...")

        
        response = s3.get_object(Bucket=S3_BUCKET_NAME, Key=INPUT_KEY)

        
        json_content = response['Body'].read().decode('utf-8')

        
        highlights = json.loads(json_content)

        
        video_url = highlights["data"][0]["url"]

        
        print(f"Processing video URL: {video_url}")

        
        print("Downloading video...")

        
        video_response = requests.get(video_url, stream=True)

        
        video_response.raise_for_status()

        
        
        video_data = BytesIO(video_response.content)

        
        print("Uploading video to S3...")

        
        s3.put_object(
            Bucket=S3_BUCKET_NAME,          
            Key=OUTPUT_KEY,                 
            Body=video_data,               
            ContentType="video/mp4"         
        )

        
        print(f"Video uploaded successfully: s3://{S3_BUCKET_NAME}/{OUTPUT_KEY}")

    except Exception as e:
        
        print(f"Error during video processing: {e}")


if __name__ == "__main__":
    process_one_video()