"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const multer_1 = __importDefault(require("multer"));
const path_1 = __importDefault(require("path"));
const openaiService_1 = require("./services/openaiService");
// Load environment variables
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3001;
// Middleware setup
app.use((0, cors_1.default)({
    origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
    credentials: true
}));
app.use(express_1.default.json());
// Configure multer for file uploads
const storage = multer_1.default.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        // Generate unique filename with timestamp
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'food-image-' + uniqueSuffix + path_1.default.extname(file.originalname));
    }
});
const upload = (0, multer_1.default)({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024 // 10MB limit
    },
    fileFilter: (req, file, cb) => {
        // Accept only image files
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        }
        else {
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
        timestamp: new Date().toISOString()
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
        const result = await (0, openaiService_1.recognizeFood)(req.file.path);
        console.log('Food recognition completed successfully'); // Debug log
        res.json(result);
    }
    catch (error) {
        console.error('Error in food recognition:', error); // Debug log
        res.status(500).json({
            error: 'Failed to process image',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Error handling middleware
app.use((error, req, res, next) => {
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
//# sourceMappingURL=index.js.map