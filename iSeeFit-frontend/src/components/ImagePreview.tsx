import React from 'react';
import './ImagePreview.css';

interface ImagePreviewProps {
  imageData: string;
  onRetake: () => void;
  onConfirm: () => void;
  isUploading?: boolean;
}

/**
 * ImagePreview Component - implements preview confirmation with retake and confirm (R1.2)
 * Displays the captured image and provides retake and confirm actions
 */
const ImagePreview: React.FC<ImagePreviewProps> = ({ 
  imageData, 
  onRetake, 
  onConfirm, 
  isUploading = false 
}) => {
  return (
    <div className="image-preview">
      <div className="preview-container">
        {/* Image preview area */}
        <div className="preview-image-container">
          <img 
            src={imageData} 
            alt="Food preview" 
            className="preview-image"
          />
          
          {/* Upload loading overlay */}
          {isUploading && (
            <div className="upload-overlay">
              <div className="upload-spinner">
                <div className="spinner"></div>
                <p>Analyzing image...</p>
              </div>
            </div>
          )}
        </div>

        {/* Preview info */}
        <div className="preview-info">
          <h3>Confirm Image</h3>
          <p>Please confirm this is the food image you want to analyze</p>
        </div>

        {/* Action buttons */}
        <div className="preview-controls">
          <button 
            className="btn btn-retake"
            onClick={onRetake}
            disabled={isUploading}
          >
            <span className="btn-icon">🔄</span>
            Retake
          </button>
          
          <button 
            className="btn btn-confirm"
            onClick={onConfirm}
            disabled={isUploading}
          >
            <span className="btn-icon">✅</span>
            {isUploading ? 'Analyzing...' : 'Confirm Analysis'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ImagePreview;
