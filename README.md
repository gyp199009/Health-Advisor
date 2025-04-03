# Personal Health Advisor System

This is an AI-powered personal health advisor system that supports uploading medical records (including text, images, and files) and real-time conversations. The AI model provides responses based on comprehensive analysis of all available medical records.

## Features

- Support for multiple medical record formats (text, images, PDF, etc.)
- Maintains coherent conversation context
- Comprehensive analysis and responses based on all uploaded medical records
- Configurable API key settings

## Tech Stack

### Frontend
- React.js
- Ant Design Component Library
- Axios for API requests

### Backend
- Node.js + Express
- MongoDB for storing user data and conversation history
- Multer for file upload handling

## Installation and Setup

### Prerequisites
- Node.js (v14+)
- MongoDB
- API keys

### Installation Steps

1. Clone repository
```
git clone [repository-url]
cd health-advisor
```

2. Install backend dependencies
```
cd backend
npm install
```

3. Install frontend dependencies
```
cd ../frontend
npm install
```

4. Configure environment variables
   - Create .env file in the backend directory and add the following:
   ```
   VOLCENGINE_API_KEY=your_volcengine_api_key
   DEEPSEEK_API_KEY=your_deepseek_api_key
   OPENAI_API_KEY=your_openai_api_key
   ANTHROPIC_API_KEY=your_anthropic_api_key
   OLLAMA_API_ENDPOINT=http://localhost:11434
   MAX_FILE_SIZE=10485760 # 10MB
   ```

5. Start the application
   - Start backend:
   ```
   cd backend
   npm start
   ```
   - Start frontend:
   ```
   cd frontend
   npm start
   ```

6. Access the application
   - Open your browser and visit http://localhost:3000

## Usage Guide

1. Register/Login to your account
2. Upload medical records (supports text, images, PDF formats)
3. Engage in conversation with the AI health advisor to receive health recommendations

## Important Notes

- This application provides reference suggestions only and cannot replace professional medical diagnosis and treatment
- Ensure uploaded medical records do not contain sensitive personal information
- Keep your API keys secure and do not share them with others