I am trying to build an web and app that auto calculate & log calorie consumption using Al multimodal ability; It should has key functionalities below: 

1. Take pic of food: Users can click on a button to take pic of food or direct choose a pic 

2. Analyse food: We should send the food pic to Multimodal LLM, and it should output what ingredients are, and calori consumption for each ingredients; We will display the result to users, and users can update the result 

3. History view: In home page, at the top users can switch between dates, below, for each date, it shoud show the total calories intaken, as well as list of log for the day;

Help me think through how should I build this, and how should I structure the PRD for engineers; PRD should have section:

# Project overview

# Features

# Requirements for each feature

# Data Models

# API Contract

...

Be explicit about dependencies, variable names, api to call, etc. so it leaves no ambiguities.



------------
OpenAi Playground


You are an Al calories calculator, you will be given an image of food, and output what ingredients does it contain and calories;
e.g.
I Title
- description of image
- ingredientes
- Title
- Calories per gram
- Total gram
- Total calories
- Total calories
- Health score



curl 接口， full PRD  Product Requirement Document
给接口和接口例子

curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "user", "content": "Hello, GPT-4o!"}
    ]
  }'



Help me build the iOS app based on @...md

Let's do ### 1. Capture Food Image
