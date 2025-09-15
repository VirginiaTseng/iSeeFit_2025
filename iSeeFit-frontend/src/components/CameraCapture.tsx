import React, { useRef, useState, useCallback } from 'react';
import './CameraCapture.css';

interface CameraCaptureProps {
  onImageCapture: (imageData: string) => void;
  onImageSelect: (file: File) => void;
}

/**
 * CameraCapture Component - 实现相机接口和图片捕获功能 (R1.1)
 * 提供相机拍照和文件选择两种方式获取图片
 */
const CameraCapture: React.FC<CameraCaptureProps> = ({ onImageCapture, onImageSelect }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [isCameraActive, setIsCameraActive] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * 启动相机功能
   * 请求用户摄像头权限并开始视频流
   */
  const startCamera = useCallback(async () => {
    try {
      console.log('Starting camera...'); // Debug log
      setError(null);
      
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: 'environment', // 使用后置摄像头
          width: { ideal: 1280 },
          height: { ideal: 720 }
        }
      });
      
      setStream(mediaStream);
      setIsCameraActive(true);
      
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
        console.log('Camera stream started successfully'); // Debug log
      }
    } catch (err) {
      console.error('Error accessing camera:', err); // Debug log
      setError('无法访问相机，请检查权限设置');
    }
  }, []);

  /**
   * 停止相机功能
   * 关闭视频流并清理资源
   */
  const stopCamera = useCallback(() => {
    console.log('Stopping camera...'); // Debug log
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      setStream(null);
      setIsCameraActive(false);
    }
  }, [stream]);

  /**
   * 捕获图片
   * 从视频流中截取当前帧并转换为图片数据
   */
  const captureImage = useCallback(() => {
    if (!videoRef.current || !canvasRef.current) {
      console.error('Video or canvas ref not available'); // Debug log
      return;
    }

    try {
      console.log('Capturing image from camera...'); // Debug log
      
      const video = videoRef.current;
      const canvas = canvasRef.current;
      const context = canvas.getContext('2d');
      
      if (!context) {
        throw new Error('无法获取画布上下文');
      }

      // 设置画布尺寸与视频相同
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      
      // 绘制当前视频帧到画布
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      
      // 转换为 base64 图片数据
      const imageData = canvas.toDataURL('image/jpeg', 0.8);
      
      console.log('Image captured successfully'); // Debug log
      onImageCapture(imageData);
      
      // 停止相机
      stopCamera();
    } catch (err) {
      console.error('Error capturing image:', err); // Debug log
      setError('图片捕获失败，请重试');
    }
  }, [onImageCapture, stopCamera]);

  /**
   * 处理文件选择
   * 当用户选择图片文件时调用
   */
  const handleFileSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      console.log('File selected:', file.name); // Debug log
      
      // 验证文件类型
      if (!file.type.startsWith('image/')) {
        setError('请选择图片文件');
        return;
      }
      
      // 验证文件大小 (10MB 限制)
      if (file.size > 10 * 1024 * 1024) {
        setError('图片文件过大，请选择小于 10MB 的文件');
        return;
      }
      
      onImageSelect(file);
    }
  }, [onImageSelect]);

  /**
   * 打开文件选择器
   */
  const openFileSelector = useCallback(() => {
    console.log('Opening file selector...'); // Debug log
    fileInputRef.current?.click();
  }, []);

  return (
    <div className="camera-capture">
      <div className="camera-container">
        {/* 视频预览区域 */}
        <div className="video-preview">
          <video
            ref={videoRef}
            autoPlay
            playsInline
            muted
            className={`camera-video ${isCameraActive ? 'active' : ''}`}
          />
          
          {/* 相机未启动时的占位符 */}
          {!isCameraActive && (
            <div className="camera-placeholder">
              <div className="camera-icon">📷</div>
              <p>点击下方按钮启动相机</p>
            </div>
          )}
        </div>

        {/* 隐藏的画布用于图片捕获 */}
        <canvas ref={canvasRef} style={{ display: 'none' }} />

        {/* 错误信息显示 */}
        {error && (
          <div className="error-message">
            <span className="error-icon">⚠️</span>
            {error}
          </div>
        )}

        {/* 控制按钮区域 */}
        <div className="camera-controls">
          {!isCameraActive ? (
            <div className="control-buttons">
              <button 
                className="btn btn-primary"
                onClick={startCamera}
              >
                📷 启动相机
              </button>
              <button 
                className="btn btn-secondary"
                onClick={openFileSelector}
              >
                📁 选择图片
              </button>
            </div>
          ) : (
            <div className="control-buttons">
              <button 
                className="btn btn-capture"
                onClick={captureImage}
              >
                📸 拍照
              </button>
              <button 
                className="btn btn-cancel"
                onClick={stopCamera}
              >
                ❌ 取消
              </button>
            </div>
          )}
        </div>

        {/* 隐藏的文件输入 */}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          onChange={handleFileSelect}
          style={{ display: 'none' }}
        />
      </div>
    </div>
  );
};

export default CameraCapture;
