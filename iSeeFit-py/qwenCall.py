#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Qwen Model API Call - Call Qwen models for various tasks
This script provides functionality to call Qwen models via API
"""

import os
import json
import requests
import logging
from typing import Dict, List, Optional, Any
from pathlib import Path
import time
from dotenv import load_dotenv

# Configure logging for debugging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class QwenAPIClient:
    """Qwen API client for calling Qwen models"""
    
    def __init__(self, api_key: str = None, base_url: str = None, env_file: str = '.env'):
        """
        Initialize the Qwen API client
        
        Args:
            api_key: API key for authentication
            base_url: Base URL for the API endpoint
            env_file: Path to .env file
        """
        # Load environment variables from .env file
        load_dotenv(env_file)
        
        self.api_key = api_key or os.getenv('QWEN_API_KEY')
        self.base_url = base_url or os.getenv('QWEN_BASE_URL', 'https://dashscope.aliyuncs.com/api/v1')
        self.session = requests.Session()
        
        if not self.api_key:
            logger.warning("No API key found. Please set QWEN_API_KEY in .env file or environment variable")
    
    def call_qwen_turbo(self, 
                       messages: List[Dict[str, str]], 
                       temperature: float = 0.7,
                       max_tokens: int = 1000) -> Dict[str, Any]:
        """
        Call Qwen Turbo model
        
        Args:
            messages: List of message dictionaries with 'role' and 'content'
            temperature: Sampling temperature (0.0 to 1.0)
            max_tokens: Maximum tokens to generate
            
        Returns:
            Dict containing the API response
        """
        return self._call_model("qwen-turbo", messages, temperature, max_tokens)
    
    def call_qwen_plus(self, 
                      messages: List[Dict[str, str]], 
                      temperature: float = 0.7,
                      max_tokens: int = 2000) -> Dict[str, Any]:
        """
        Call Qwen Plus model
        
        Args:
            messages: List of message dictionaries with 'role' and 'content'
            temperature: Sampling temperature (0.0 to 1.0)
            max_tokens: Maximum tokens to generate
            
        Returns:
            Dict containing the API response
        """
        return self._call_model("qwen-plus", messages, temperature, max_tokens)
    
    def call_qwen_max(self, 
                     messages: List[Dict[str, str]], 
                     temperature: float = 0.7,
                     max_tokens: int = 4000) -> Dict[str, Any]:
        """
        Call Qwen Max model
        
        Args:
            messages: List of message dictionaries with 'role' and 'content'
            temperature: Sampling temperature (0.0 to 1.0)
            max_tokens: Maximum tokens to generate
            
        Returns:
            Dict containing the API response
        """
        return self._call_model("qwen-max", messages, temperature, max_tokens)
    
    def _call_model(self, 
                   model: str, 
                   messages: List[Dict[str, str]], 
                   temperature: float,
                   max_tokens: int) -> Dict[str, Any]:
        """
        Internal method to call any Qwen model
        
        Args:
            model: Model name to call
            messages: List of message dictionaries
            temperature: Sampling temperature
            max_tokens: Maximum tokens to generate
            
        Returns:
            Dict containing the API response
        """
        try:
            logger.info(f"Calling {model} model...")
            
            url = f"{self.base_url}/services/aigc/text-generation/generation"
            
            headers = {
                'Authorization': f'Bearer {self.api_key}',
                'Content-Type': 'application/json'
            }
            
            payload = {
                "model": model,
                "input": {
                    "messages": messages
                },
                "parameters": {
                    "temperature": temperature,
                    "max_tokens": max_tokens
                }
            }
            
            logger.debug(f"Request payload: {json.dumps(payload, indent=2)}")
            
            response = self.session.post(url, headers=headers, json=payload, timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                logger.info(f"Successfully called {model} model")
                return result
            else:
                logger.error(f"API call failed with status {response.status_code}: {response.text}")
                return {
                    "error": f"API call failed with status {response.status_code}",
                    "details": response.text
                }
                
        except requests.exceptions.Timeout:
            logger.error("Request timeout")
            return {"error": "Request timeout"}
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error: {e}")
            return {"error": f"Request error: {str(e)}"}
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            return {"error": f"Unexpected error: {str(e)}"}
    
    def analyze_food_image(self, image_path: str, question: str = "What food is in this image?") -> Dict[str, Any]:
        """
        Analyze food image using Qwen Vision model
        
        Args:
            image_path: Path to the food image
            question: Question about the image
            
        Returns:
            Dict containing the analysis result
        """
        try:
            logger.info(f"Analyzing food image: {image_path}")
            
            # Read and encode image
            with open(image_path, 'rb') as f:
                import base64
                image_data = base64.b64encode(f.read()).decode('utf-8')
            
            messages = [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": question
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{image_data}"
                            }
                        }
                    ]
                }
            ]
            
            # Use qwen-vl model for vision tasks
            return self._call_model("qwen-vl-plus", messages, temperature=0.3, max_tokens=1000)
            
        except FileNotFoundError:
            logger.error(f"Image file not found: {image_path}")
            return {"error": f"Image file not found: {image_path}"}
        except Exception as e:
            logger.error(f"Error analyzing image: {e}")
            return {"error": f"Error analyzing image: {str(e)}"}
    
    def get_nutrition_analysis(self, food_description: str) -> Dict[str, Any]:
        """
        Get nutrition analysis for food description
        
        Args:
            food_description: Description of the food
            
        Returns:
            Dict containing nutrition analysis
        """
        messages = [
            {
                "role": "system",
                "content": "You are a nutrition expert. Analyze the given food and provide detailed nutritional information including calories, macronutrients, and health score."
            },
            {
                "role": "user",
                "content": f"Please analyze the nutrition of this food: {food_description}. Provide calories per 100g, protein, carbs, fat, and a health score from 1-10."
            }
        ]
        
        return self.call_qwen_plus(messages, temperature=0.3, max_tokens=500)
    
    def suggest_healthy_alternatives(self, current_food: str) -> Dict[str, Any]:
        """
        Suggest healthy alternatives for given food
        
        Args:
            current_food: Current food item
            
        Returns:
            Dict containing healthy alternatives
        """
        messages = [
            {
                "role": "system",
                "content": "You are a nutritionist and fitness expert. Suggest healthy alternatives for the given food that are lower in calories and higher in nutritional value."
            },
            {
                "role": "user",
                "content": f"Suggest 3-5 healthy alternatives for: {current_food}. Include brief explanations of why each alternative is better."
            }
        ]
        
        return self.call_qwen_plus(messages, temperature=0.5, max_tokens=800)


def main():
    """Main function to demonstrate Qwen model calls"""
    print("Qwen Model API Caller")
    print("=" * 30)
    
    # Initialize API client
    client = QwenAPIClient()
    
    if not client.api_key:
        print("❌ No API key found. Please set QWEN_API_KEY in .env file")
        print("Create a .env file with:")
        print("QWEN_API_KEY=your_api_key_here")
        print("QWEN_BASE_URL=https://dashscope.aliyuncs.com/api/v1  # optional")
        return
    
    print("✅ API client initialized successfully")
    
    # Example usage
    print("\nChoose an example:")
    print("1. Simple text generation")
    print("2. Food nutrition analysis")
    print("3. Healthy alternatives suggestion")
    print("4. Food image analysis (requires image file)")
    
    try:
        choice = input("\nEnter your choice (1-4): ").strip()
        
        if choice == "1":
            # Simple text generation example
            messages = [
                {"role": "user", "content": "Hello! Can you tell me about healthy eating habits?"}
            ]
            
            print("\nCalling Qwen Turbo for text generation...")
            result = client.call_qwen_turbo(messages)
            
            if "error" in result:
                print(f"❌ Error: {result['error']}")
            else:
                print("✅ Response received:")
                if "output" in result and "text" in result["output"]:
                    print(result["output"]["text"])
                else:
                    print(json.dumps(result, indent=2))
        
        elif choice == "2":
            # Nutrition analysis example
            food = input("Enter food description: ").strip()
            if food:
                print(f"\nAnalyzing nutrition for: {food}")
                result = client.get_nutrition_analysis(food)
                
                if "error" in result:
                    print(f"❌ Error: {result['error']}")
                else:
                    print("✅ Nutrition analysis:")
                    if "output" in result and "text" in result["output"]:
                        print(result["output"]["text"])
                    else:
                        print(json.dumps(result, indent=2))
        
        elif choice == "3":
            # Healthy alternatives example
            food = input("Enter food item for alternatives: ").strip()
            if food:
                print(f"\nFinding healthy alternatives for: {food}")
                result = client.suggest_healthy_alternatives(food)
                
                if "error" in result:
                    print(f"❌ Error: {result['error']}")
                else:
                    print("✅ Healthy alternatives:")
                    if "output" in result and "text" in result["output"]:
                        print(result["output"]["text"])
                    else:
                        print(json.dumps(result, indent=2))
        
        elif choice == "4":
            # Image analysis example
            image_path = input("Enter path to food image: ").strip()
            if image_path and os.path.exists(image_path):
                print(f"\nAnalyzing image: {image_path}")
                result = client.analyze_food_image(image_path)
                
                if "error" in result:
                    print(f"❌ Error: {result['error']}")
                else:
                    print("✅ Image analysis:")
                    if "output" in result and "text" in result["output"]:
                        print(result["output"]["text"])
                    else:
                        print(json.dumps(result, indent=2))
            else:
                print("❌ Image file not found")
        
        else:
            print("Invalid choice. Please run the script again.")
    
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user.")
    except Exception as e:
        print(f"\nError: {e}")
        logger.error(f"Unexpected error in main: {e}")


if __name__ == "__main__":
    main()