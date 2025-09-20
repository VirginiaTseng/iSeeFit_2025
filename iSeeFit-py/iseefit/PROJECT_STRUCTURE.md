# iSeeFit Backend Project Structure

## 📁 Directory Organization

```
backend/
├── app/                          # Main application
│   └── main.py                   # FastAPI app entry point
├── config/                       # Configuration files
│   ├── database.py               # Database connection and models
│   └── settings.py               # Application settings
├── models/                       # Data models and schemas
│   ├── __init__.py               # Models package init
│   ├── user.py                   # User model
│   ├── meal.py                   # Meal record model
│   ├── workout.py                # Workout record model
│   ├── recommendation.py         # Recommendation model
│   └── schemas.py                # Pydantic schemas
├── routes/                       # API routes
│   ├── auth.py                   # Authentication routes
│   ├── meals.py                  # Meal record routes
│   ├── workouts.py               # Workout record routes
│   └── recommendations.py        # Recommendation routes
├── services/                     # Business logic services
│   ├── __init__.py               # Services package init
│   └── recommendation_service.py # Recommendation engine
├── utils/                        # Utility functions
│   ├── __init__.py               # Utils package init
│   ├── auth.py                   # Authentication utilities
│   └── image.py                  # Image processing utilities
├── requirements.txt              # Python dependencies
├── README.md                     # Project documentation
└── create_database.py            # Database initialization script
```

## 🏗️ Architecture Overview

### **app/**
- **main.py**: FastAPI application entry point
- Configures CORS, includes all routers, defines main endpoints

### **config/**
- **database.py**: Database connection, engine, and session management
- **settings.py**: Application configuration from environment variables

### **models/**
- **user.py**: User model and database table definition
- **meal.py**: Meal record model and database table definition
- **workout.py**: Workout record model and database table definition
- **recommendation.py**: Recommendation model and database table definition
- **schemas.py**: Pydantic models for request/response validation

### **routes/**
- **auth.py**: User registration, login, and profile endpoints
- **meals.py**: Meal record CRUD operations and statistics
- **workouts.py**: Workout record CRUD operations and statistics
- **recommendations.py**: Recommendation management endpoints

### **services/**
- **recommendation_service.py**: AI-powered recommendation engine
- Generates personalized meal and workout recommendations

### **utils/**
- **auth.py**: Password hashing, JWT token management, authentication
- **image.py**: Image upload, compression, and file management

## 🔄 Data Flow

1. **Request** → **Routes** → **Services** → **Models** → **Database**
2. **Response** ← **Schemas** ← **Models** ← **Database** ← **Services**

## 🚀 Key Features

- **Modular Architecture**: Clean separation of concerns
- **Type Safety**: Pydantic schemas for data validation
- **Authentication**: JWT-based user authentication
- **Image Processing**: Automatic image compression and storage
- **AI Recommendations**: Personalized fitness and nutrition advice
- **Statistics**: Comprehensive data analytics and reporting

## 📊 Database Schema

- **users**: User profiles and preferences
- **meal_records**: Food intake tracking
- **workout_records**: Exercise activity logging
- **recommendations**: AI-generated personalized advice

## 🔧 Configuration

All configuration is managed through environment variables:
- Database connection settings
- JWT secret keys
- File upload limits
- Logging levels

## 🧪 Testing

Each module can be tested independently:
- Unit tests for services and utilities
- Integration tests for routes
- Database tests for models

## 📈 Scalability

The modular structure supports:
- Easy addition of new features
- Independent scaling of components
- Clean API versioning
- Microservices migration if needed
