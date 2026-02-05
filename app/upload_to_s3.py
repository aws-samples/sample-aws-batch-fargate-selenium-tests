import boto3
import os

def upload_file_to_s3(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = file_name

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.upload_file(file_name, bucket, object_name)
    except Exception as e:
        print(f"Error uploading to S3: {str(e)}")
        return False
    return True

if __name__ == "__main__":
    # Retrieve S3 bucket name from environment variable
    s3_bucket = os.environ.get('S3_BUCKET_NAME')

    if not s3_bucket:
        print("S3_BUCKET_NAME environment variable not set")
        exit(1)

    # Retrieve runId from environment variable
    run_id = os.environ.get('RUN_ID')

    if not run_id:
        print("RUN_ID environment variable not set")
        exit(1)

    # Upload report to S3
    if upload_file_to_s3('report.html', s3_bucket, f'test_reports/runjob{run_id}/report.html'):
        print(f"Successfully uploaded report to s3://{s3_bucket}/test_reports/runjob{run_id}/report.html")
    else:
        print("Failed to upload report to S3")
