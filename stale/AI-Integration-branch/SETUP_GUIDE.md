# BioTective Health Platform - Complete Setup Guide

This guide will help you set up both the Flutter frontend and AI backend for the BioTective Digital Health Platform.

## 📋 Prerequisites

### Required Software
- **Python 3.8+** - For AI backend
- **Flutter SDK** - For mobile app (if available, otherwise we'll use the manual setup)
- **Git** - For version control
- **Code Editor** - VS Code recommended

### API Key
- DeepSeek API key is already configured in the code

## 🚀 Quick Setup

### Step 1: Test AI Backend

1. **Navigate to AI Integration Directory**
   ```bash
   cd ai_integration
   ```

2. **Test AI Modules**
   ```bash
   python test_simple.py
   ```
   This should show all modules importing successfully.

3. **Install Python Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Start AI Backend Server**
   ```bash
   python ai_backend/main.py
   ```
   The server will start on `http://localhost:5000`

5. **Test API Endpoints**
   ```bash
   python test_api.py
   ```
   This will test all AI endpoints with sample data.

### Step 2: Flutter App Setup

1. **Navigate to Flutter App Directory**
   ```bash
   cd biotective_health_app
   ```

2. **Install Flutter Dependencies** (if Flutter is installed)
   ```bash
   flutter pub get
   ```

3. **Generate Model Files** (if Flutter is installed)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run Flutter App** (if Flutter is installed)
   ```bash
   flutter run
   ```

## 🔧 Manual Flutter Setup (If Flutter SDK Not Available)

Since Flutter SDK might not be installed, the project structure is already created manually. Here's what's included:

### Project Structure
```
biotective_health_app/
├── lib/
│   ├── main.dart                    # Main app entry point
│   ├── models/
│   │   └── patient_data.dart        # Data models
│   ├── services/
│   │   └── ai_service.dart          # AI service integration
│   ├── screens/
│   │   ├── home_screen.dart         # Home screen
│   │   ├── patient_dashboard_screen.dart
│   │   ├── clinician_dashboard_screen.dart
│   │   ├── chatbot_screen.dart
│   │   └── recommendations_screen.dart
│   └── widgets/
│       ├── glucose_chart.dart
│       ├── activity_chart.dart
│       └── health_score_card.dart
└── pubspec.yaml                     # Dependencies
```

## 🧪 Testing the Integration

### 1. Start AI Backend
```bash
cd ai_integration
python ai_backend/main.py
```

### 2. Test API Endpoints
Open a new terminal and run:
```bash
cd ai_integration
python test_api.py
```

### 3. Test Flutter Integration
If you have Flutter installed:
```bash
cd biotective_health_app
flutter run
```

## 📱 Flutter App Features

### Home Screen
- AI service connection status
- Navigation to different dashboards
- Health check for backend connectivity

### Patient Dashboard
- Health score visualization
- Glucose trend charts
- Activity tracking charts
- AI-generated insights
- Health alerts and anomalies
- Quick access to chatbot and recommendations

### AI Chatbot (Florence)
- Context-aware health conversations
- Emergency detection
- Conversation history
- Personalized responses based on patient data

### Recommendations Screen
- Personalized health recommendations
- Detailed explanations for each recommendation
- Priority-based categorization
- Action items for each recommendation

### Clinician Dashboard
- Multi-patient overview
- Risk level assessment
- Patient prioritization
- Anomaly summaries
- Health score tracking

## 🔗 API Integration

The Flutter app communicates with the AI backend through RESTful APIs:

### Key Endpoints
- `GET /api/health` - Health check
- `POST /api/recommendations` - Get personalized recommendations
- `POST /api/chatbot/message` - Chatbot interaction
- `POST /api/anomaly-detection` - Detect health anomalies
- `POST /api/automation/triggers` - Process automation triggers
- `POST /api/insights` - Get comprehensive health insights
- `POST /api/clinician/dashboard` - Clinician dashboard data

### Data Flow
1. Flutter app generates sample patient data
2. Sends data to AI backend via HTTP requests
3. AI backend processes data using DeepSeek API
4. Returns structured JSON responses
5. Flutter app displays results in UI components

## 🛠️ Troubleshooting

### Common Issues

#### 1. Python Import Errors
```bash
# Make sure you're in the ai_integration directory
cd ai_integration
python test_simple.py
```

#### 2. API Connection Issues
- Ensure AI backend is running on `http://localhost:5000`
- Check firewall settings
- Verify Python dependencies are installed

#### 3. Flutter Dependencies
If Flutter is not installed, the app structure is ready for when you install Flutter SDK.

#### 4. DeepSeek API Issues
- API key is pre-configured
- Check internet connection
- Verify API endpoint is accessible

### Debug Commands

```bash
# Test AI modules
python ai_integration/test_simple.py

# Test API endpoints
python ai_integration/test_api.py

# Check server status
curl http://localhost:5000/api/health
```

## 📊 Sample Data

The system includes comprehensive sample data generation:

- **Patient Data**: Realistic glucose readings, activity data, diet logs
- **Multiple Patients**: For clinician dashboard testing
- **Various Scenarios**: High/low glucose, different activity levels
- **Time-based Data**: Last 7-30 days of health data

## 🎯 Project Milestones Achieved

✅ **Milestone 1**: Project setup with data simulation and security
✅ **Milestone 2**: Patient dashboard with data processing and visualization
✅ **Milestone 3**: AI-powered recommendation engine with explainability
✅ **Milestone 4**: Automation layer (LAM triggers) for alerts and reminders
✅ **Milestone 5**: Clinician dashboard and chatbot interface
✅ **Milestone 6**: Testing, security, and final integration

## 🚀 Next Steps

1. **Install Flutter SDK** (if not already installed)
2. **Run the AI backend** to test all functionality
3. **Test the Flutter app** with the AI integration
4. **Customize the UI** based on your team's design requirements
5. **Add real patient data** integration
6. **Deploy to production** using the deployment guide

## 📞 Support

For technical issues:
1. Check the troubleshooting section
2. Run the test scripts to verify functionality
3. Review the API documentation in the code
4. Check the Flutter integration guide for mobile-specific issues

The AI integration is fully functional and ready for Flutter development!
