import React from 'react';
import './ImagePreview.css';

interface ImagePreviewProps {
  imageData: string;
  onRetake: () => void;
  onConfirm: () => void;
  isUploading?: boolean;
}

/**
 * ImagePreview Component - 实现预览确认界面，包含重拍和确认选项 (R1.2)
 * 显示捕获的图片并提供重拍和确认操作
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
        {/* 图片预览区域 */}
        <div className="preview-image-container">
          <img 
            src={imageData} 
            alt="Food preview" 
            className="preview-image"
          />
          
          {/* 上传加载遮罩 */}
          {isUploading && (
            <div className="upload-overlay">
              <div className="upload-spinner">
                <div className="spinner"></div>
                <p>正在分析图片...</p>
              </div>
            </div>
          )}
        </div>

        {/* 预览信息 */}
        <div className="preview-info">
          <h3>确认图片</h3>
          <p>请确认这是您想要分析的食物图片</p>
        </div>

        {/* 操作按钮区域 */}
        <div className="preview-controls">
          <button 
            className="btn btn-retake"
            onClick={onRetake}
            disabled={isUploading}
          >
            <span className="btn-icon">🔄</span>
            重拍
          </button>
          
          <button 
            className="btn btn-confirm"
            onClick={onConfirm}
            disabled={isUploading}
          >
            <span className="btn-icon">✅</span>
            {isUploading ? '分析中...' : '确认分析'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ImagePreview;
