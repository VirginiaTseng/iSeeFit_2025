# iSeeFit Test Setup Guide

## Quick Test Steps

### 1. Environment Setup

**Backend environment variables:**
```bash
cd iSeeFit-backend
cp .env.example .env
# Edit .env and add your OpenAI API Key
```

**Frontend environment variables:**
```bash
cd iSeeFit-frontend
# Create .env.local file
echo "VITE_API_URL=http://localhost:3001" > .env.local
```

### 2. Start Services

**Method A: use the start script**
```bash
./start-dev.sh
```

**Method B: start separately**
```bash
# Terminal 1 - Backend
cd iSeeFit-backend
npm run dev

# Terminal 2 - Frontend  
cd iSeeFit-frontend
npm run dev
```

### 3. Test the features

1. Open the browser at http://localhost:5173
2. Click the "Start Camera" button
3. Allow the browser to access your camera
4. Aim at the food and take a photo
5. On the preview page click "Confirm Analysis"
6. View the AI analysis results

### 4. Test file upload

1. Click the "Choose Image" button
2. Select a food image
3. On the preview page click "Confirm Analysis"
4. View the AI analysis results

## Expected Results

- ✅ Camera works as expected
- ✅ Image preview UI renders correctly
- ✅ Image is uploaded to backend successfully
- ✅ AI analysis returns nutrition data
- ✅ Results page shows calories and ingredients

## Troubleshooting

### Camera cannot start
- Ensure HTTPS or localhost is used
- Check browser permission settings
- Try refreshing the page

### API request fails
- Check if backend is running (http://localhost:3001/api/health)
- Ensure OpenAI API Key is configured properly
- Inspect browser console errors

### Image upload fails
- Check image file size (< 10MB)
- Ensure supported formats (JPEG, PNG, WebP)
- Check your network connection
