#!/bin/bash

# Start Selenium server in background (using the image's built-in setup)
/opt/bin/start-selenium-standalone.sh &

# Wait for Selenium server to be ready
echo "Waiting for Selenium server to start..."
for i in {1..30}; do
    if curl -s http://localhost:4444/status | grep -q '"ready":true'; then
        echo "Selenium server is ready!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

# Run tests and generate report
echo "Running tests..."
pytest test_sample.py --html=report.html --self-contained-html -v || true

# Upload report to S3 regardless of test result
./upload_to_s3.sh
