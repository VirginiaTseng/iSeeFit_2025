import axios from 'axios';

// API base configuration
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001';

// Create axios instance
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000, // 30s timeout
  headers: {
    'Content-Type': 'application/json',
  },
});

// Food recognition result interface
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
 * Convert base64 image data to Blob
 * @param base64Data - base64-encoded image data
 * @returns Blob object
 */
function base64ToBlob(base64Data: string): Blob {
  console.log('Converting base64 to blob...'); // Debug log
  
  // Remove data:image/jpeg;base64, prefix
  const base64String = base64Data.split(',')[1];
  const binaryString = atob(base64String);
  const bytes = new Uint8Array(binaryString.length);
  
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  
  return new Blob([bytes], { type: 'image/jpeg' });
}

/**
 * Upload image for food recognition
 * @param imageData - base64 image data or File object
 * @returns Promise<FoodRecognitionResult> - recognition result
 */
export async function recognizeFood(imageData: string | File): Promise<FoodRecognitionResult> {
  try {
    console.log('Starting food recognition API call...'); // Debug log
    
    let formData: FormData;
    
    if (typeof imageData === 'string') {
      // Handle base64 data
      console.log('Processing base64 image data'); // Debug log
      const blob = base64ToBlob(imageData);
      formData = new FormData();
      formData.append('image', blob, 'food-image.jpg');
    } else {
      // Handle File object
      console.log('Processing file object:', imageData.name); // Debug log
      formData = new FormData();
      formData.append('image', imageData);
    }
    
    console.log('Sending request to /api/recognize endpoint'); // Debug log
    
    const response = await apiClient.post<FoodRecognitionResult>('/api/recognize', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    
    console.log('Food recognition API response received:', response.data); // Debug log
    
    return response.data;
  } catch (error) {
    console.error('Error in food recognition API:', error); // Debug log
    
    if (axios.isAxiosError(error)) {
      const errorMessage = error.response?.data?.error || error.message;
      throw new Error(`Food recognition failed: ${errorMessage}`);
    } else {
      throw new Error('Food recognition failed: Network error');
    }
  }
}

/**
 * Check API health status
 * @returns Promise<boolean> - whether API is available
 */
export async function checkApiHealth(): Promise<boolean> {
  try {
    console.log('Checking API health...'); // Debug log
    
    const response = await apiClient.get('/api/health');
    
    console.log('API health check response:', response.data); // Debug log
    
    return response.status === 200;
  } catch (error) {
    console.error('API health check failed:', error); // Debug log
    return false;
  }
}

/**
 * Get API base URL
 * @returns string - API base URL
 */
export function getApiBaseUrl(): string {
  return API_BASE_URL;
}
