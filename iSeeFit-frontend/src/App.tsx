import { useState, useCallback } from 'react';
import './App.css';
import CameraCapture from './components/CameraCapture';
import ImagePreview from './components/ImagePreview';
import { recognizeFood, type FoodRecognitionResult } from './services/apiService';

/**
 * 主应用组件 - 整合图片捕获和上传功能
 * 实现 R1.1, R1.2, R1.3 所有要求
 */
function App() {
  // 状态管理
  const [currentView, setCurrentView] = useState<'camera' | 'preview' | 'results'>('camera');
  const [capturedImage, setCapturedImage] = useState<string>('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [recognitionResult, setRecognitionResult] = useState<FoodRecognitionResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  /**
   * 处理图片捕获 (R1.1)
   * 从相机捕获的 base64 图片数据
   */
  const handleImageCapture = useCallback((imageData: string) => {
    console.log('Image captured from camera'); // Debug log
    setCapturedImage(imageData);
    setSelectedFile(null);
    setError(null);
    setCurrentView('preview');
  }, []);

  /**
   * 处理文件选择 (R1.1)
   * 用户选择的图片文件
   */
  const handleImageSelect = useCallback((file: File) => {
    console.log('File selected:', file.name); // Debug log
    
    // 将文件转换为 base64 用于预览
    const reader = new FileReader();
    reader.onload = (e) => {
      const result = e.target?.result as string;
      setCapturedImage(result);
      setSelectedFile(file);
      setError(null);
      setCurrentView('preview');
    };
    reader.readAsDataURL(file);
  }, []);

  /**
   * 处理重拍操作 (R1.2)
   * 返回相机界面重新拍摄
   */
  const handleRetake = useCallback(() => {
    console.log('Retaking photo...'); // Debug log
    setCapturedImage('');
    setSelectedFile(null);
    setError(null);
    setRecognitionResult(null);
    setCurrentView('camera');
  }, []);

  /**
   * 处理确认上传 (R1.2, R1.3)
   * 上传图片到后端进行 AI 分析
   */
  const handleConfirmUpload = useCallback(async () => {
    try {
      console.log('Starting image upload and analysis...'); // Debug log
      setIsUploading(true);
      setError(null);

      // 准备上传数据
      const imageData = selectedFile || capturedImage;
      if (!imageData) {
        throw new Error('没有可上传的图片数据');
      }

      console.log('Uploading image to backend...'); // Debug log
      
      // 调用 API 进行食物识别
      const result = await recognizeFood(imageData);
      
      console.log('Food recognition completed:', result); // Debug log
      
      setRecognitionResult(result);
      setCurrentView('results');
    } catch (err) {
      console.error('Upload failed:', err); // Debug log
      setError(err instanceof Error ? err.message : '上传失败，请重试');
    } finally {
      setIsUploading(false);
    }
  }, [capturedImage, selectedFile]);

  /**
   * 返回相机界面
   */
  const handleBackToCamera = useCallback(() => {
    console.log('Returning to camera...'); // Debug log
    setCurrentView('camera');
    setCapturedImage('');
    setSelectedFile(null);
    setError(null);
    setRecognitionResult(null);
  }, []);

  // 渲染结果页面
  const renderResults = () => {
    if (!recognitionResult) return null;

    return (
      <div className="results-container">
        <div className="results-header">
          <h2>🍽️ 食物分析结果</h2>
          <button className="btn btn-back" onClick={handleBackToCamera}>
            📷 重新拍摄
          </button>
        </div>
        
        <div className="results-content">
          <div className="food-image">
            <img src={capturedImage} alt="Analyzed food" />
          </div>
          
          <div className="analysis-results">
            <h3>{recognitionResult.title}</h3>
            
            <div className="summary-cards">
              <div className="summary-card">
                <div className="card-value">{recognitionResult.totalCalories}</div>
                <div className="card-label">总卡路里</div>
              </div>
              <div className="summary-card">
                <div className="card-value">{recognitionResult.healthScore}/10</div>
                <div className="card-label">健康评分</div>
              </div>
            </div>
            
            <div className="ingredients-list">
              <h4>成分分析</h4>
              {recognitionResult.ingredients.map((ingredient, index) => (
                <div key={index} className="ingredient-item">
                  <div className="ingredient-name">{ingredient.name}</div>
                  <div className="ingredient-details">
                    <span>{ingredient.totalGrams}g</span>
                    <span>{ingredient.totalCalories}卡路里</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>🍎 iSeeFit</h1>
        <p>AI 智能食物识别与卡路里分析</p>
      </header>

      <main className="App-main">
        {error && (
          <div className="error-banner">
            <span className="error-icon">⚠️</span>
            {error}
            <button 
              className="error-close"
              onClick={() => setError(null)}
            >
              ✕
            </button>
          </div>
        )}

        {currentView === 'camera' && (
          <CameraCapture
            onImageCapture={handleImageCapture}
            onImageSelect={handleImageSelect}
          />
        )}

        {currentView === 'preview' && (
          <ImagePreview
            imageData={capturedImage}
            onRetake={handleRetake}
            onConfirm={handleConfirmUpload}
            isUploading={isUploading}
          />
        )}

        {currentView === 'results' && renderResults()}
      </main>
    </div>
  );
}

export default App;