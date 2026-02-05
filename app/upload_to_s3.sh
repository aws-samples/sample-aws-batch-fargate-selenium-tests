#!/bin/bash
set -e

S3_BUCKET="${S3_BUCKET_NAME}"
RUN_ID="${RUN_ID}"

if [ -z "$S3_BUCKET" ]; then
    echo "S3_BUCKET_NAME environment variable not set"
    exit 1
fi

if [ -z "$RUN_ID" ]; then
    echo "RUN_ID environment variable not set"
    exit 1
fi

S3_PATH="s3://${S3_BUCKET}/test_reports/runjob${RUN_ID}/report.html"

echo "Uploading report to ${S3_PATH}..."
aws s3 cp report.html "${S3_PATH}"
echo "Successfully uploaded report to ${S3_PATH}"
