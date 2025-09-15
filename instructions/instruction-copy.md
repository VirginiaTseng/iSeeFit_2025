## Product Name
**iSeeFit** - An web and mobile application for automated calorie and nutrition logging through AI-powered food recognition.
## Purpose & Scope
This PRD details the functionality and technical specifications for the iSeeFit iS application. It provides requirements on user flows, data structures, backend integration, UI components, error handling, as well as smooth animations for transitioning between the image confirmation screen and the AI recognition results page.

## Key Features•
1. **Food- Image Capture & Recognition**
2. **AI-Powered Ingredient & Nutrition Analysis**
3. **Manual Editing of Results**
4. **Daily Summary & History View**
5. **Smooth Animated Transitions**
6. **Settings & Integration **

## Feature Requirements


**User• Story:**
As a user, I can capture a meal photo and confirm it before submitting to the AI service.
**Requirements:**
- **R1.1:** A camera interface enabling users to capture an image of their meal.
- **R1.2:** On capture, a preview (confirmation screen) appears with "Retake" and "Use Photo" or "Confirm" options.
- **R1.3:** Upon confirmation, upload the image to the backend Al endpoint and display a loading state.


### 2. AI Recognition & Nutritional Analysis
**User Story:**
As a user, when I confirm my photo, the system analyzes it and returns ingredient identification, calorie estimates, and macros.
**Requirements:**
- **R2.1:** 'POST /api/recognize' endpoint to handle image upload and return a JSON response with specified ingredients, total calories, macros, and a health score.
- **R2.2:** Parse the response and present it on a results screen that overlays recognized food on the image and shows details in a bottom card.

**Example of AI model api service**
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "user", "content": "Hello, GPT-4o!"}
    ]
  }'
