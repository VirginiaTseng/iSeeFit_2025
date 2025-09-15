import { useState, useCallback } from 'react';
import './App.css';
import CameraCapture from './components/CameraCapture';
import ImagePreview from './components/ImagePreview';
import { recognizeFood, type FoodRecognitionResult } from './services/apiService';

/**
 * Main application component - integrates image capture and upload flow
 * Implements requirements R1.1, R1.2, R1.3
 */
function App() {
  // State management
  const [currentView, setCurrentView] = useState<'camera' | 'preview' | 'results'>('camera');
  const [capturedImage, setCapturedImage] = useState<string>('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [recognitionResult, setRecognitionResult] = useState<FoodRecognitionResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  /**
   * Handle image capture (R1.1)
   * Base64 image data captured from the camera
   */
  const handleImageCapture = useCallback((imageData: string) => {
    console.log('Image captured from camera'); // Debug log
    setCapturedImage(imageData);
    setSelectedFile(null);
    setError(null);
    setCurrentView('preview');
  }, []);

  /**
   * Handle file selection (R1.1)
   * The image file selected by the user
   */
  const handleImageSelect = useCallback((file: File) => {
    console.log('File selected:', file.name); // Debug log
    
    // Convert file to base64 for preview
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
   * Handle retake action (R1.2)
   * Return to the camera view for retaking a photo
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
   * Handle confirm upload (R1.2, R1.3)
   * Upload the image to backend for AI analysis
   */
  const handleConfirmUpload = useCallback(async () => {
    try {
      console.log('Starting image upload and analysis...'); // Debug log
      setIsUploading(true);
      setError(null);

      // Prepare upload data
      const imageData = selectedFile || capturedImage;
      if (!imageData) {
        throw new Error('No image data to upload');
      }

      console.log('Uploading image to backend...'); // Debug log
      
      // Call API for food recognition
      const result = await recognizeFood(imageData);
      
      console.log('Food recognition completed:', result); // Debug log
      
      setRecognitionResult(result);
      setCurrentView('results');
    } catch (err) {
      console.error('Upload failed:', err); // Debug log
      setError(err instanceof Error ? err.message : 'Upload failed, please try again');
    } finally {
      setIsUploading(false);
    }
  }, [capturedImage, selectedFile]);

  /**
   * Return to camera view
   */
  const handleBackToCamera = useCallback(() => {
    console.log('Returning to camera...'); // Debug log
    setCurrentView('camera');
    setCapturedImage('');
    setSelectedFile(null);
    setError(null);
    setRecognitionResult(null);
  }, []);

  // Render results page
  const renderResults = () => {
    if (!recognitionResult) return null;

    return (
      <div className="results-container">
        <div className="results-header">
          <h2>🍽️ Food Analysis Results</h2>
          <button className="btn btn-back" onClick={handleBackToCamera}>
            📷 Retake
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
                <div className="card-label">Total Calories</div>
              </div>
              <div className="summary-card">
                <div className="card-value">{recognitionResult.healthScore}/10</div>
                <div className="card-label">Health Score</div>
              </div>
            </div>
            
            <div className="ingredients-list">
              <h4>Ingredient Analysis</h4>
              {recognitionResult.ingredients.map((ingredient, index) => (
                <div key={index} className="ingredient-item">
                  <div className="ingredient-name">{ingredient.name}</div>
                  <div className="ingredient-details">
                    <span>{ingredient.totalGrams}g</span>
                    <span>{ingredient.totalCalories} calories</span>
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
        <p>AI food recognition and calorie analysis</p>
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