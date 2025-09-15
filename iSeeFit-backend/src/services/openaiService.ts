import OpenAI from 'openai';
import fs from 'fs';

// Initialize OpenAI client (may be undefined if no key)
const openaiApiKey = process.env.OPENAI_API_KEY;
const openai = openaiApiKey
  ? new OpenAI({ apiKey: openaiApiKey })
  : undefined;

// Interface for food recognition result
export interface FoodRecognitionResult {
  ingredients: Array<{
    name: string;
    description: string;
    caloriesPerGram: number;
    totalGrams: number;
    totalCalories: number;
  }>;
  totalCalories: number;
  healthScore: number;
  title: string;
}

/**
 * Analyze food image using OpenAI's GPT-4 Vision model
 * @param imagePath - Path to the uploaded image file
 * @returns Promise<FoodRecognitionResult> - Structured food analysis result
 */
export async function recognizeFood(imagePath: string): Promise<FoodRecognitionResult> {
  try {
    console.log(`Starting food recognition for image: ${imagePath}`); // Debug log
    
    // Read image file and convert to base64
    const imageBuffer = fs.readFileSync(imagePath);
    const base64Image = imageBuffer.toString('base64');
    
    // If no OpenAI API key, return a mock response for local development
    if (!openai) {
      console.warn('[openaiService] OPENAI_API_KEY not set, returning mock analysis result'); // Debug log
      const mock: FoodRecognitionResult = {
        title: 'Sample Dish (Local Mock)',
        ingredients: [
          {
            name: 'White Rice',
            description: 'A small bowl of cooked rice',
            caloriesPerGram: 1.3,
            totalGrams: 150,
            totalCalories: Math.round(1.3 * 150)
          },
          {
            name: 'Pan-seared Chicken Breast',
            description: 'Skinless chicken breast, pan-seared with minimal oil',
            caloriesPerGram: 1.65,
            totalGrams: 120,
            totalCalories: Math.round(1.65 * 120)
          }
        ],
        totalCalories: Math.round(1.3 * 150 + 1.65 * 120),
        healthScore: 7
      };
      console.log('[openaiService] Mock result ready'); // Debug log
      return mock;
    }

    console.log('Image converted to base64, calling OpenAI API'); // Debug log
    
    // Call OpenAI API with the image
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: `You are an AI calories calculator. Analyze this food image and provide detailed nutritional information. 
              Please respond with a JSON object containing:
              - title: A descriptive title for the food
              - ingredients: Array of objects with name, description, caloriesPerGram, totalGrams, totalCalories
              - totalCalories: Sum of all ingredient calories
              - healthScore: A score from 1-10 (10 being healthiest)
              
              Be as accurate as possible with portion sizes and nutritional values.`
            },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${base64Image}`
              }
            }
          ]
        }
      ],
      max_tokens: 2000,
      temperature: 0.3
    });

    console.log('OpenAI API response received'); // Debug log
    
    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error('No response content from OpenAI');
    }

    // Parse JSON response
    let result: FoodRecognitionResult;
    try {
      result = JSON.parse(content);
    } catch (parseError) {
      console.error('Failed to parse OpenAI response as JSON:', parseError); // Debug log
      // Fallback: create a basic response structure
      result = {
        title: "Food Analysis",
        ingredients: [{
          name: "Unknown Food",
          description: "Unable to analyze this food item",
          caloriesPerGram: 0,
          totalGrams: 0,
          totalCalories: 0
        }],
        totalCalories: 0,
        healthScore: 5
      };
    }

    console.log('Food recognition completed successfully'); // Debug log
    return result;

  } catch (error) {
    console.error('Error in food recognition service:', error); // Debug log
    throw new Error(`Food recognition failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
