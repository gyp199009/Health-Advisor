# Personal Health Advisor System

This is an AI-powered personal health advisor system that supports uploading medical records (including text, images, and files) and real-time conversations. The AI model provides responses based on comprehensive analysis of all available medical records.

## Features

- Support for multiple medical record formats (text, images, PDF, etc.)
- Maintains coherent conversation context
- Comprehensive analysis and responses based on all uploaded medical records
- Configurable API key settings

## Tech Stack

### Frontend
#### Web Frontend
- React.js
- Ant Design Component Library
- Axios for API requests

#### Mobile Frontend (Android)
- Flutter SDK
- Provider for state management
- HTTP package for API requests
- Flutter Markdown for rendering content

### Backend
- Node.js + Express
- MongoDB for storing user data and conversation history
- Multer for file upload handling

## Installation and Setup

### Prerequisites
- Node.js (v14+)
- MongoDB
- API keys
- Flutter SDK (v3.9+) for Android development
- Android Studio with Android SDK installed
- JDK 11 or newer

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

3. Install web frontend dependencies
```
cd ../frontend
npm install
```

4. Install Flutter frontend dependencies
```
cd ../flutter_frontend
flutter pub get
```

5. Configure environment variables
   - Create .env file in the backend directory and add the following:
   ```
   VOLCENGINE_API_KEY=your_volcengine_api_key
   DEEPSEEK_API_KEY=your_deepseek_api_key
   OPENAI_API_KEY=your_openai_api_key
   ANTHROPIC_API_KEY=your_anthropic_api_key
   OLLAMA_API_ENDPOINT=http://localhost:11434
   MAX_FILE_SIZE=10485760 # 10MB
   ```

6. Start the application
   - Start backend:
   ```
   cd backend
   npm start
   ```
   - Start web frontend:
   ```
   cd frontend
   npm start
   ```
   - Run Flutter Android app:
   ```
   cd flutter_frontend
   flutter run
   ```
   或者使用Android Studio打开flutter_frontend/android目录并运行应用

7. Access the application
   - Web版本: 打开浏览器访问 http://localhost:3000
   - Android版本: 通过Flutter运行在连接的Android设备或模拟器上

## Usage Guide

### Web版本
1. 注册/登录您的账户
2. 上传医疗记录（支持文本、图像、PDF格式）
3. 与AI健康顾问进行对话，获取健康建议

### Android版本
1. 在Android设备上安装并启动应用
2. 注册/登录您的账户
3. 上传医疗记录（支持文本、图像格式）
4. 与AI健康顾问进行对话，获取健康建议

### Flutter开发指南
1. 项目结构
   - lib/: 包含所有Dart源代码
   - android/: Android平台特定配置
   - ios/: iOS平台特定配置（如需支持）
   - pubspec.yaml: 依赖管理配置文件

2. 构建Android APK
   ```
   cd flutter_frontend
   flutter build apk --release
   ```
   生成的APK文件位于`flutter_frontend/build/app/outputs/flutter-apk/app-release.apk`

## Demo
http://ec2-18-142-230-119.ap-southeast-1.compute.amazonaws.com

## Important Notes

- This application provides reference suggestions only and cannot replace professional medical diagnosis and treatment
- Ensure uploaded medical records do not contain sensitive personal information
- Keep your API keys secure and do not share them with others