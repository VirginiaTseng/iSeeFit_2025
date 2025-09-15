import axios from 'axios';

// API 基础配置
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001';

// 创建 axios 实例
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000, // 30秒超时
  headers: {
    'Content-Type': 'application/json',
  },
});

// 食物识别结果接口
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
 * 将 base64 图片数据转换为 Blob 对象
 * @param base64Data - base64 编码的图片数据
 * @returns Blob 对象
 */
function base64ToBlob(base64Data: string): Blob {
  console.log('Converting base64 to blob...'); // Debug log
  
  // 移除 data:image/jpeg;base64, 前缀
  const base64String = base64Data.split(',')[1];
  const binaryString = atob(base64String);
  const bytes = new Uint8Array(binaryString.length);
  
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  
  return new Blob([bytes], { type: 'image/jpeg' });
}

/**
 * 上传图片进行食物识别
 * @param imageData - base64 编码的图片数据或 File 对象
 * @returns Promise<FoodRecognitionResult> - 食物识别结果
 */
export async function recognizeFood(imageData: string | File): Promise<FoodRecognitionResult> {
  try {
    console.log('Starting food recognition API call...'); // Debug log
    
    let formData: FormData;
    
    if (typeof imageData === 'string') {
      // 处理 base64 数据
      console.log('Processing base64 image data'); // Debug log
      const blob = base64ToBlob(imageData);
      formData = new FormData();
      formData.append('image', blob, 'food-image.jpg');
    } else {
      // 处理 File 对象
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
      throw new Error(`食物识别失败: ${errorMessage}`);
    } else {
      throw new Error('食物识别失败: 网络错误');
    }
  }
}

/**
 * 检查 API 健康状态
 * @returns Promise<boolean> - API 是否可用
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
 * 获取 API 基础 URL
 * @returns string - API 基础 URL
 */
export function getApiBaseUrl(): string {
  return API_BASE_URL;
}
