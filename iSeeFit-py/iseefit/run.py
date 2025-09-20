#!/usr/bin/env python3
"""
iSeeFit Backend Server Runner
"""

import uvicorn
import os
import sys
from pathlib import Path

# Add backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.append(str(backend_dir))

def main():
    """Run the FastAPI server"""
    # Check environment variables
    if not os.getenv("SECRET_KEY") or os.getenv("SECRET_KEY") == "your-secret-key-here-change-in-production":
        print("⚠️  WARNING: Please set a secure SECRET_KEY in your environment variables!")
        print("   Example: export SECRET_KEY='your-very-secure-secret-key-here'")
        print()
    
    # Server configuration
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    reload = os.getenv("RELOAD", "true").lower() == "true"
    
    print("🚀 Starting iSeeFit Backend API server...")
    print(f"   Host: {host}")
    print(f"   Port: {port}")
    print(f"   Reload: {reload}")
    print(f"   API Documentation: http://{host}:{port}/docs")
    print(f"   ReDoc Documentation: http://{host}:{port}/redoc")
    print()
    
    # Start server
    uvicorn.run(
        "app.main:app",
        host=host,
        port=port,
        reload=reload,
        log_level="info"
    )

if __name__ == "__main__":
    main()
