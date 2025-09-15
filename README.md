# iSeeFit - AI Food Recognition and Calorie Analysis App

## Project Overview

iSeeFit is an AI-powered web app that recognizes food from photos and automatically estimates calories and nutritional components. It uses OpenAI's GPT-4 Vision model for food recognition and analysis.

## Features

### 1. Image capture and upload ✅
- **R1.1**: Camera interface, supports taking photos and selecting files
- **R1.2**: Preview confirmation screen with retake and confirm options  
- **R1.3**: Uploads image to backend AI endpoint with loading state

### 2. AI recognition and nutrition analysis
- Uses OpenAI GPT-4 Vision to analyze food images
- Recognizes food items and nutritional components
- Calculates total calories and a health score
- Provides detailed ingredient analysis

## Tech Stack

### Frontend
- React 18 + TypeScript
- Vite (build tool)
- Axios (HTTP client)
- CSS3 (styling)

### Backend
- Node.js + Express
- TypeScript
- OpenAI API
- Multer (file upload)
- CORS (cross-origin support)

## Project Structure

```
iSeeFit/
├── iSeeFit-frontend/          # React frontend app
│   ├── src/
│   │   ├── components/        # React components
│   │   │   ├── CameraCapture.tsx    # camera capture component
│   │   │   ├── CameraCapture.css
│   │   │   ├── ImagePreview.tsx     # image preview component
│   │   │   └── ImagePreview.css
│   │   ├── services/          # API services
│   │   │   └── apiService.ts
│   │   ├── App.tsx           # main app component
│   │   └── App.css
│   └── package.json
├── iSeeFit-backend/           # Node.js backend API
│   ├── src/
│   │   ├── services/
│   │   │   └── openaiService.ts     # OpenAI service
│   │   └── index.ts          # main server file
│   ├── uploads/              # image upload directory
│   └── package.json
└── README.md
```

## Quick Start

### 1. Prerequisites

Make sure you have:
- Node.js (v18+ recommended)
- npm or yarn

### 2. Backend setup

```bash
cd iSeeFit-backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env and add your OpenAI API Key
# OPENAI_API_KEY=your_actual_api_key_here

# Start backend
npm run dev
```

Backend will run at http://localhost:3001

### 3. Frontend setup

```bash
cd iSeeFit-frontend

# Install dependencies
npm install

# Start dev server
npm run dev
```

Frontend will run at http://localhost:5173

## API Endpoints

### POST /api/recognize
Upload image for food recognition

**Request:**
- Content-Type: multipart/form-data
- Body: image (file)

**Response:**
```json
{
  "title": "Food Name",
  "ingredients": [
    {
      "name": "Ingredient Name",
      "description": "Ingredient description",
      "caloriesPerGram": 4.2,
      "totalGrams": 150,
      "totalCalories": 630
    }
  ],
  "totalCalories": 630,
  "healthScore": 7
}
```

### GET /api/health
Health check endpoint

**Response:**
```json
{
  "status": "OK",
  "message": "iSeeFit Backend is running",
  "timestamp": "2025-01-03 13:21:51"
}
```

## Usage

1. **Start camera**: Click "Start Camera" and allow browser camera access
2. **Take photo**: Aim at the food and click "Take Photo"
3. **Preview**: Review the image, choose "Retake" or "Confirm Analysis"
4. **AI analysis**: The image is sent to OpenAI for analysis
5. **View results**: See detailed nutrition and calorie analysis

## Development Notes

### Debug logs
All components include detailed debug logs to aid development and debugging:
- Camera operation logs
- API call logs
- Error handling logs

### Error handling
- Camera permission errors
- File upload errors
- API request errors
- Network connection errors

## Notes

1. A valid OpenAI API Key is required
2. HTTPS is required for camera access in production
3. Image file size limit: 10MB
4. Supported formats: JPEG, PNG, WebP

## Next Steps

- [ ] History feature
- [ ] User account system
- [ ] Data persistence
- [ ] Mobile optimizations
- [ ] Offline support
