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
export declare function recognizeFood(imagePath: string): Promise<FoodRecognitionResult>;
//# sourceMappingURL=openaiService.d.ts.map