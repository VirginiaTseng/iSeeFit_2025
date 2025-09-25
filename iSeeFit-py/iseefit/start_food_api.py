#!/usr/bin/env python3
"""
Start Food Analysis API Server
For testing and development environment
"""

import os
import sys
from pathlib import Path

# 添加项目路径
project_dir = Path(__file__).parent
sys.path.append(str(project_dir))

def main():
    """Start server"""
    print("🚀 Starting iSeeFit Food Analysis API server...")
    print("   Address: http://localhost:8000")
    print("   API Documentation: http://localhost:8000/docs")
    print("   Food Analysis Endpoint: http://localhost:8000/api/food/analyze")
    print()
    
    # Check environment variables
    if not os.getenv("OPENAI_API_KEY"):
        print("⚠️  Warning: OPENAI_API_KEY not set, will use Food-101 classifier as fallback")
        print("   To enable OpenAI functionality, set environment variable:")
        print("   export OPENAI_API_KEY='your-api-key-here'")
        print()
    
    # Start server
    try:
        import uvicorn
        from app.main import app
        
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )
    except KeyboardInterrupt:
        print("\n👋 Server stopped")
    except Exception as e:
        print(f"❌ Startup failed: {e}")

if __name__ == "__main__":
    main()
