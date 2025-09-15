import React, { useRef, useState, useCallback } from 'react';
import './CameraCapture.css';

interface CameraCaptureProps {
  onImageCapture: (imageData: string) => void;
  onImageSelect: (file: File) => void;
}

/**
 * CameraCapture Component - implements camera interface and image capture (R1.1)
 * Provides two ways to acquire an image: take a photo or select a file
 */
const CameraCapture: React.FC<CameraCaptureProps> = ({ onImageCapture, onImageSelect }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [isCameraActive, setIsCameraActive] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * Start camera
   * Request camera permission and start the video stream
   */
  const startCamera = useCallback(async () => {
    try {
      console.log('Starting camera...'); // Debug log
      setError(null);
      
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: 'environment', // Use rear camera for better framing
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
      setError('Unable to access camera. Please check permission settings.');
    }
  }, []);

  /**
   * Stop camera
   * Close the media stream and clean up resources
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
   * Capture image
   * Grab current frame from the video stream and convert to image data
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
        throw new Error('Unable to get canvas 2D context');
      }

      // Match canvas size to video
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      
      // Draw current video frame to canvas
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      
      // Convert to base64 image data
      const imageData = canvas.toDataURL('image/jpeg', 0.8);
      
      console.log('Image captured successfully'); // Debug log
      onImageCapture(imageData);
      
      // Stop camera after capture
      stopCamera();
    } catch (err) {
      console.error('Error capturing image:', err); // Debug log
      setError('Failed to capture image. Please try again.');
    }
  }, [onImageCapture, stopCamera]);

  /**
   * Handle file selection
   * Triggered when user selects an image file
   */
  const handleFileSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      console.log('File selected:', file.name); // Debug log
      
      // Validate file type
      if (!file.type.startsWith('image/')) {
        setError('Please select an image file.');
        return;
      }
      
      // Validate file size (10MB limit)
      if (file.size > 10 * 1024 * 1024) {
        setError('File is too large. Please select a file under 10MB.');
        return;
      }
      
      onImageSelect(file);
    }
  }, [onImageSelect]);

  /**
   * Open file selector
   */
  const openFileSelector = useCallback(() => {
    console.log('Opening file selector...'); // Debug log
    fileInputRef.current?.click();
  }, []);

  return (
    <div className="camera-capture">
      <div className="camera-container">
        {/* Video preview area */}
        <div className="video-preview">
          <video
            ref={videoRef}
            autoPlay
            playsInline
            muted
            className={`camera-video ${isCameraActive ? 'active' : ''}`}
          />
          
          {/* Placeholder when camera is not active */}
          {!isCameraActive && (
            <div className="camera-placeholder">
              <div className="camera-icon">📷</div>
              <p>Click the button below to start the camera</p>
            </div>
          )}
        </div>

        {/* Hidden canvas for image capture */}
        <canvas ref={canvasRef} style={{ display: 'none' }} />

        {/* Error message */}
        {error && (
          <div className="error-message">
            <span className="error-icon">⚠️</span>
            {error}
          </div>
        )}

        {/* Control buttons */}
        <div className="camera-controls">
          {!isCameraActive ? (
            <div className="control-buttons">
              <button 
                className="btn btn-primary"
                onClick={startCamera}
              >
                📷 Start Camera
              </button>
              <button 
                className="btn btn-secondary"
                onClick={openFileSelector}
              >
                📁 Choose Image
              </button>
            </div>
          ) : (
            <div className="control-buttons">
              <button 
                className="btn btn-capture"
                onClick={captureImage}
              >
                📸 Take Photo
              </button>
              <button 
                className="btn btn-cancel"
                onClick={stopCamera}
              >
                ❌ Cancel
              </button>
            </div>
          )}
        </div>

        {/* Hidden file input */}
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
