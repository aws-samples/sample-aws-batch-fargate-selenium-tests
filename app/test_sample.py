import pytest
import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import WebDriverException

@pytest.fixture
def driver():
    chrome_options = Options()
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    
    driver = webdriver.Remote(
        command_executor='http://localhost:4444',
        options=chrome_options
    )
    yield driver
    try:
        driver.quit()
    except WebDriverException:
        pass

def test_browser_capabilities(driver):
    """Test that browser is working and can execute JavaScript"""
    # Use data URL - no internet required
    driver.get("data:text/html,<html><head><title>Test Page</title></head><body><h1 id='header'>Hello Selenium</h1></body></html>")
    
    assert "Test Page" in driver.title
    header = driver.find_element(By.ID, "header")
    assert header.text == "Hello Selenium"
    print("Browser capabilities test passed!")

def test_javascript_execution(driver):
    """Test JavaScript execution in browser"""
    driver.get("data:text/html,<html><body><div id='result'></div></body></html>")
    
    # Execute JavaScript
    driver.execute_script("document.getElementById('result').innerText = 'JS Works!'")
    
    result = driver.find_element(By.ID, "result")
    assert result.text == "JS Works!"
    print("JavaScript execution test passed!")

def test_form_interaction(driver):
    """Test form input and button interaction"""
    html = """
    <html>
    <body>
        <input type='text' id='name' />
        <button id='submit' onclick="document.getElementById('output').innerText='Hello, ' + document.getElementById('name').value">Submit</button>
        <div id='output'></div>
    </body>
    </html>
    """
    driver.get(f"data:text/html,{html}")
    
    # Fill form
    name_input = driver.find_element(By.ID, "name")
    name_input.send_keys("Selenium Test")
    
    # Click button
    submit_btn = driver.find_element(By.ID, "submit")
    submit_btn.click()
    
    # Verify output
    output = driver.find_element(By.ID, "output")
    assert "Hello, Selenium Test" in output.text
    print("Form interaction test passed!")

def test_environment_variables():
    """Verify required environment variables are set"""
    run_id = os.environ.get('RUN_ID')
    bucket = os.environ.get('S3_BUCKET_NAME')
    
    assert run_id is not None, "RUN_ID environment variable not set"
    assert bucket is not None, "S3_BUCKET_NAME environment variable not set"
    print(f"Environment check passed - RUN_ID: {run_id}, Bucket: {bucket}")
