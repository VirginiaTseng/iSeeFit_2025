#!/usr/bin/env python3
"""
Food Analysis API Test Script
Used to test if food analysis functionality works properly
"""

import requests
import json
from PIL import Image
import io
import os

# 测试配置
API_BASE_URL = "http://localhost:8000"
TEST_IMAGE_PATH = "/Users/virginiazheng/Documents/Workspaces/Hackathon2025/iSeeFit_2025/iSeeFit-py/1737322834349.JPG"

def test_health_check():
    """Test health check endpoint"""
    print("🔍 Testing health check endpoint...")
    try:
        response = requests.get(f"{API_BASE_URL}/api/food/health")
        if response.status_code == 200:
            print("✅ Health check passed")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Health check exception: {e}")

def test_config():
    """Test config endpoint"""
    print("\n🔍 Testing config endpoint...")
    try:
        response = requests.get(f"{API_BASE_URL}/api/food/config")
        if response.status_code == 200:
            print("✅ Config retrieval successful")
            config = response.json()
            print(f"   OpenAI enabled: {config.get('openai_enabled', False)}")
            print(f"   Model name: {config.get('model_name', 'N/A')}")
            print(f"   Fallback classifier: {config.get('fallback_classifier', 'N/A')}")
            if 'openai_error' in config:
                print(f"   OpenAI error: {config['openai_error']}")
        else:
            print(f"❌ Config retrieval failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Config retrieval exception: {e}")

def test_food_analysis():
    """Test food analysis endpoint"""
    print("\n🔍 Testing food analysis endpoint...")
    
    # Check if test image exists
    if not os.path.exists(TEST_IMAGE_PATH):
        print(f"❌ Test image does not exist: {TEST_IMAGE_PATH}")
        return
    
    try:
        # Prepare test data
        with open(TEST_IMAGE_PATH, 'rb') as f:
            image_data = f.read()
        
        files = {
            'image': ('test_food.jpg', image_data, 'image/jpeg')
        }
        
        data = {
            'use_ai_portions': True,
            'manual_override': '',
            'portion_slider': 250.0
        }
        
        print("   Sending analysis request...")
        response = requests.post(
            f"{API_BASE_URL}/api/food/analyze",
            files=files,
            data=data,
            timeout=60  # Increase timeout as AI analysis may take longer
        )
        
        if response.status_code == 200:
            print("✅ Food analysis successful")
            result = response.json()
            
            print(f"   Timestamp: {result.get('timestamp', 'N/A')}")
            print(f"   Mode: {result.get('mode', 'N/A')}")
            print(f"   Number of detected foods: {len(result.get('per_item', []))}")
            
            # Display information for each food item
            for i, item in enumerate(result.get('per_item', []), 1):
                print(f"   Food {i}: {item.get('Food (detected)', 'N/A')}")
                print(f"     Portion: {item.get('Portion (g)', 0)}g")
                print(f"     Calories: {item.get('Calories (kcal)', 0)}kcal")
                print(f"     Confidence: {item.get('Confidence', 0)}")
            
            # Display totals
            totals = result.get('totals', {})
            if totals:
                print(f"   Totals:")
                print(f"     Total portion: {totals.get('Portion (g)', 0)}g")
                print(f"     Total calories: {totals.get('Calories (kcal)', 0)}kcal")
                print(f"     Total protein: {totals.get('Protein (g)', 0)}g")
                print(f"     Total carbs: {totals.get('Carbs (g)', 0)}g")
                print(f"     Total fat: {totals.get('Fat (g)', 0)}g")
            
            # Save results to file
            output_file = "test_analysis_result.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            print(f"   Results saved to: {output_file}")
            
        else:
            print(f"❌ Food analysis failed: {response.status_code}")
            print(f"   Error message: {response.text}")
            
    except Exception as e:
        print(f"❌ Food analysis exception: {e}")

def main():
    """Main test function"""
    print("🚀 Starting food analysis API tests...")
    print(f"   API URL: {API_BASE_URL}")
    print(f"   Test image: {TEST_IMAGE_PATH}")
    print()
    
    # Run tests
    test_health_check()
    test_config()
    test_food_analysis()
    
    print("\n✨ Tests completed!")

if __name__ == "__main__":
    main()
