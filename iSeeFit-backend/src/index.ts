import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import multer from 'multer';
import path from 'path';
import { recognizeFood } from './services/openaiService';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware setup
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  credentials: true
}));
app.use(express.json());

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'food-image-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'));
    }
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  console.log('Health check endpoint called'); // Debug log
  res.json({ 
    status: 'OK', 
    message: 'iSeeFit Backend is running',
    // Use preferred date-time format: YYYY-MM-DD HH:mm:ss
    timestamp: new Date().toISOString().replace('T', ' ').replace('Z', '')
  });
});

// Food recognition endpoint - R2.1 requirement
app.post('/api/recognize', upload.single('image'), async (req, res) => {
  try {
    console.log('Food recognition request received'); // Debug log
    
    if (!req.file) {
      console.log('No image file provided'); // Debug log
      return res.status(400).json({ 
        error: 'No image file provided' 
      });
    }

    console.log(`Processing image: ${req.file.filename}`); // Debug log
    
    // Call OpenAI service for food recognition
    const result = await recognizeFood(req.file.path);
    
    console.log('Food recognition completed successfully'); // Debug log
    
    res.json(result);
  } catch (error) {
    console.error('Error in food recognition:', error); // Debug log
    res.status(500).json({ 
      error: 'Failed to process image',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Error handling middleware
app.use((error: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Unhandled error:', error); // Debug log
  res.status(500).json({ 
    error: 'Internal server error',
    details: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`iSeeFit Backend server running on port ${PORT}`); // Debug log
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`); // Debug log
});
