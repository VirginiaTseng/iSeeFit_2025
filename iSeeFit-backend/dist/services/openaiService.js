"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.recognizeFood = recognizeFood;
const openai_1 = __importDefault(require("openai"));
const fs_1 = __importDefault(require("fs"));
// Initialize OpenAI client
const openai = new openai_1.default({
    apiKey: process.env.OPENAI_API_KEY,
});
/**
 * Analyze food image using OpenAI's GPT-4 Vision model
 * @param imagePath - Path to the uploaded image file
 * @returns Promise<FoodRecognitionResult> - Structured food analysis result
 */
async function recognizeFood(imagePath) {
    try {
        console.log(`Starting food recognition for image: ${imagePath}`); // Debug log
        // Read image file and convert to base64
        const imageBuffer = fs_1.default.readFileSync(imagePath);
        const base64Image = imageBuffer.toString('base64');
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
        let result;
        try {
            result = JSON.parse(content);
        }
        catch (parseError) {
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
    }
    catch (error) {
        console.error('Error in food recognition service:', error); // Debug log
        throw new Error(`Food recognition failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
}
//# sourceMappingURL=openaiService.js.map