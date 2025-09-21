#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Simple Food Advisor - Extracted from food_detection.ipynb
AI recommendation from health condition and food name (simple consle input and output)
"""

import re
import os
from openai import OpenAI
from dotenv import load_dotenv

def markdown_to_text(markdown_text):
    """
    Clean markdown format - copied from the food_detection.ipynb final Cell

    Convert markdown format to plain text
    """
    print("🧹 正在清理markdown格式...")
    
    text = re.sub(r'^#+ ', '', markdown_text)           # 移除标题标记 #
    text = re.sub(r'\*\*|__|~|`', '', text)             # 移除粗体、斜体、代码标记
    text = re.sub(r'^\* ', '', text, flags=re.MULTILINE)  # 移除列表标记
    text = re.sub(r'\[.*?\]\(.*?\)', '', text)          # 移除链接
    return text.strip()

def setup_api_client():
    """
    Set up API client - check and configure available API
    
    Load .env file and check available API
    """
    print("🔧 Setting up API client...")
    
    # 加载环境变量
    load_dotenv()
    print("📁 .enf file loaded")
    
    # 检查OpenAI密钥
    openai_key = os.getenv('OPENAI_API_KEY')
    if openai_key and openai_key.startswith('sk-') and len(openai_key) > 20:
        print("✅ OpenAI API key found")
        client = OpenAI(api_key=openai_key)
        return client, "gpt-3.5-turbo", "OpenAI"
    
    # 检查Qwen密钥
    qwen_key = os.getenv('QWEN_API_KEY')
    qwen_base_url = os.getenv('QWEN_BASE_URL')
    if qwen_key and len(qwen_key) > 20:
        print("✅ Qwen API key found")
        client = OpenAI(
            api_key=qwen_key,
            base_url=qwen_base_url
        )
        return client, "qwen-turbo", "Qwen"
    
    # 没有找到可用密钥
    print("❌ No available API key found in .env file")
    return None, None, None

def build_prompt(food_name,health_condition,prompt_style):
    """
    Build prompt based on food namd, health condition and prompt style
    Args:
        prompt_style: "simple" or "professional" or "detailed"
    Returns:
        (system_prompt, user_prompt)
    """
    # Arrya of system prompts, provide 3 options
    system_prompts = {
        "simple": "You are a helpful health advisor.",
        
        "professional": """You are a certified nutritionist and health consultant with 10+ years of experience. 
You provide evidence-based, practical health advice about food choices for people with specific health conditions. 
Your responses are clear, actionable, and consider both nutritional science and practical lifestyle factors.""",
        
        "detailed": """You are a board-certified nutritionist and clinical dietitian specializing in therapeutic nutrition. 
You have extensive knowledge of:
- Food composition and nutritional values
- Medical nutrition therapy for various health conditions
- Drug-nutrient interactions
- Evidence-based dietary guidelines
- Practical meal planning and food substitutions
Provide comprehensive, scientifically accurate advice while being accessible to non-medical audiences."""
    }

    # Different user prompts based on prompt style
    if (prompt_style == "simple"):
        user_prompt = f"I have health condition: '{health_condition}' , and I want to know is that ok for me to eat food: '{food_name}', please give me the advice in a short paragraph."
    elif (prompt_style == "professional"):
        user_prompt = f"""Please analyze the following food choice for someone with my health condition:
**Health Condition:** {health_condition}
**Food Item:** {food_name}
Please provide:
1. Safety assessment (safe/caution/avoid)
2. Key nutritional concerns
3. Practical recommendations
4. Alternative suggestions if needed
Keep the response concise but informative."""
    elif (prompt_style == "detailed"):
        user_prompt = f"""I need a comprehensive nutritional assessment for the following scenario:
**Patient Profile:**
- Health Condition: {health_condition}
- Dietary Query: Consumption of {food_name}
**Please provide a detailed analysis including:**
1. **Safety Assessment**
   - Is this food safe for my condition?
   - Risk level (low/moderate/high)
2. **Nutritional Analysis**
   - Key nutrients in {food_name}
   - How these nutrients affect {health_condition}
   - Portion size recommendations
3. **Clinical Considerations**
   - Potential interactions with common medications for {health_condition}
   - Timing considerations (if any)
4. **Practical Recommendations**
   - Preparation methods to reduce risks
   - Frequency of consumption
   - Healthier alternatives
5. **Action Items**
   - Immediate steps to take
   - When to consult healthcare provider
Please base your response on current nutritional science and clinical guidelines."""
    
    return system_prompts[prompt_style], user_prompt


def get_food_advice(food_name, health_condition, prompt_style):
    """
    Get diet advice based on food name and health condition(core function extracted from food_detection.ipynb final Cell)
    
    This is the core function extracted from food_detection.ipynb final Cell
    
    Params:
        food_name
        health_condition
    """
    
    # Step1: Set up API client
    print(f"\n🎯 Analysis Start: {food_name} (Health Condition: {health_condition})")
    print("-" * 50)
    
    client, model, provider = setup_api_client()
    if not client:
        return "❌ API config failed, please check the API key config in .env file."
    
    print(f"🔑 Usring: {provider} API, Model: {model}")
    
    # Step2: Build prompt
    system_prompt,user_prompt = build_prompt(food_name,health_condition,prompt_style)
    print(f"📝 System Prompt: {system_prompt}")
    print(f"📝 User Prompt: {user_prompt}")

    try:
        # 步骤3: 调用API (完全复制原始API调用结构)
        print("🤖 Calling AI API...")
        print("⏳ Please wait for AI response...")
        
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            stream=True  # enable stream response, can see the AI generating process in real time
        )
        
        print("📡 Receiving stream response:")
        print("-" * 30)
        
        # Step4: Process stream response
        full_content = ""
        chunk_count = 0
        
        for chunk in response:
            chunk_count += 1
            # 提取内容 - 与原始代码完全一致的逻辑
            content = chunk.choices[0].delta.content if chunk.choices[0].delta.content is not None else ""
            full_content += content
            
            # 实时显示AI生成的内容 (增强用户体验)
            if content:
                print(content, end='', flush=True)
        
        print(f"\n\n✅ Received {chunk_count} chunks")
        
        # 步骤5: Format Cleaning using markdown_to_text function
        print("🧹 Cleaning response format...")
        cleaned_result = markdown_to_text(full_content)
        
        return cleaned_result
        
    except Exception as e:
        error_msg = f"❌ API call failed: {str(e)}"
        print(error_msg)
        return error_msg

def main():
    """
    Main function to demonstrate the complete AI call process
    """
    
    print("🧑‍⚕️ Simple Food Advisor")
    print("=" * 60)
    
    print("\n📋 : Interactive of AI call process")
    
    while True:
        print("\n" + "-" * 40)
        print("Please choose the operation:")
        print("1. Input custom food, health condition and response preference")
        print("2. Show the process description")
        print("3. Exit the program")
        
        choice = input("\nPlease choose (1-3): ").strip()
        
        if choice == '1':
            food = input("\nPlease input the food name: ").strip()
            if not food:
                print("❌ Food name cannot be empty")
                continue
                
            condition = input("Please input the health condition: ").strip()
            if not condition:
                print("❌ Health condition cannot be empty")
                continue

            prompt_style = input("Please input the response preference(simple/professional/detailed): ").strip()
            if not prompt_style or prompt_style not in ["simple", "professional", "detailed"]:
                print("❌ Response preference should be simple/professional/detailed and cannot be empty")
                continue
            
            # call core function
            result = get_food_advice(food, condition, prompt_style)
            
            print("\n" + "=" * 50)
            print("🎯 AI diet advice:")
            print("=" * 50)
            print(result)
            
        elif choice == '2':
            print("\n📖 AI call process description:")
            print("1️⃣  Load API key (.env file)")
            print("2️⃣  Initialize OpenAI client")
            print("3️⃣  Build prompt (user question)")
            print("4️⃣  Send API request (stream=True)")
            print("5️⃣  Receive stream response (real-time display)")
            print("6️⃣  Clean markdown format")
            print("7️⃣  Return final result")
            
        elif choice == '3':
            break
            
        else:
            print("❌ Invalid choice, please choose 1-3")

if __name__ == "__main__":
    main()