# Florence Platform - BioTective Patient Dashboard

A comprehensive cross-platform health management application built with Flutter, designed for chronic disease monitoring.

## Overview

Florence Platform is a patient-centric digital health dashboard that empowers individuals to actively monitor and manage chronic conditions. The application provides real-time health tracking, AI-powered insights, personalized recommendations, and seamless integration with healthcare providers.

### Key Features

- **Real-time Health Monitoring** - Track glucose levels, meals, physical activity, and medications
- **AI Health Assistant** - Conversational AI providing personalized health guidance and pattern recognition
- **Advanced Analytics** - Visualize health trends with interactive charts and time-in-range analysis
- **Personalized Recommendations** - AI-driven insights based on individual health patterns
- **Gamification** - Streak tracking, achievements, and point systems to encourage healthy behaviors
- **Cross-Platform** - Works on Android, iOS, Web, Windows, macOS, and Linux from a single codebase
- **Offline-First Architecture** - Continue logging health data even without internet connection
- **HIPAA-Compliant** - Secure data handling with encryption and privacy controls

## Technology Stack

### Frontend
- **Framework**: Flutter ^3.7.2
- **Language**: Dart ^3.7.2
- **UI Design**: Material Design 3
- **State Management**: Provider ^6.1.1

### Backend & Services
- **Backend**: Supabase (Backend-as-a-Service)
  - PostgreSQL database
  - Real-time subscriptions
  - Authentication
  - File storage
- **HTTP Client**: http ^1.2.0

### Data Visualization
- **Charts**: fl_chart ^0.66.0
  - Line charts for glucose trends
  - Bar charts for daily statistics
  - Pie/donut charts for time-in-range
  - Heatmaps for pattern analysis

### Utilities
- **Internationalization**: intl ^0.19.0
- **Image Handling**: image_picker ^1.0.7, cached_network_image ^3.3.1
- **Serialization**: json_annotation ^4.8.1, json_serializable ^6.7.1

### Development Tools
- **Code Generation**: build_runner ^2.4.8
- **Linting**: flutter_lints ^5.0.0

## Project Structure

```
florence/
├── lib/
│   ├── main.dart                 # Application entry point
│   ├── app.dart                  # App configuration and routing
│   ├── config/                   # Configuration files
│   │   ├── env.dart             # Environment variables
│   │   ├── constants.dart       # App-wide constants
│   │   ├── theme.dart           # Material Design 3 theme
│   │   └── routes.dart          # Navigation routing
│   ├── core/                     # Core functionality
│   │   ├── models/              # Data models
│   │   ├── services/            # Service layer
│   │   ├── utils/               # Utilities and helpers
│   │   └── widgets/             # Reusable UI components
│   ├── features/                 # Feature modules
│   │   ├── auth/                # Authentication
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── patient/             # Patient features
│   │       ├── dashboard/       # Main dashboard
│   │       ├── logging/         # Data entry screens
│   │       ├── trends/          # Analytics & visualization
│   │       ├── profile/         # User profile
│   │       ├── chat/            # AI assistant
│   │       └── recommendations/ # AI recommendations
│   └── shared/                   # Shared widgets and resources
├── Document/                     # Project documentation
│   ├── Patient/                 # Patient app specifications
│   └── Admin/                   # Admin platform documentation
├── android/                      # Android-specific files
├── ios/                          # iOS-specific files
├── web/                          # Web-specific files
├── windows/                      # Windows desktop files
├── linux/                        # Linux desktop files
├── macos/                        # macOS desktop files
└── pubspec.yaml                  # Dependencies
```

## Features by Module

### Authentication
- User registration with email validation
- Secure login with Supabase Auth
- Password strength validation
- Splash screen with authentication check
- Demo mode for testing without backend

### Dashboard
- At-a-glance health overview
- Current glucose status with color coding
- Quick statistics summary
- Quick action buttons for data logging
- Featured AI insights
- Upcoming reminders
- Active alerts section
- Pull-to-refresh functionality

### Data Logging
**Glucose Monitoring**
- Large, easy-to-read input interface
- Real-time color coding (Green/Yellow/Red)
- 6 context options (Before Meal, After Meal 1hr/2hr, Fasting, Before Bed, Random)
- Reference range display
- Validation (20-600 mg/dL)

**Meal Tracking**
- 4 meal types (Breakfast, Lunch, Dinner, Snack)
- Macro tracking (Carbs, Protein, Fat)
- Automatic calorie calculation
- Visual calorie badge

**Activity Logging**
- 8 activity types with color-coded icons
- Duration input (1-480 minutes)
- 3 intensity levels
- Estimated calorie burn calculation

**Medication Tracking**
- 6 medication types
- Dosage tracking
- 6 timing options
- Safety warnings

### Analytics & Trends
- Interactive glucose trend charts
- Multiple time period views (Today, 3 Days, Week, Month)
- Time-in-range visualization
- Statistical analysis (avg, std dev, estimated HbA1c)
- AI pattern insights
- Meal and activity impact analysis

### AI Health Assistant
- Conversational interface
- Suggested starter questions
- Context-aware responses
- Typing indicators
- Message timestamps
- Voice input support (planned)
- Privacy-focused AI interaction

### User Profile
- Personal information management
- Health summary card
- Achievement tracking
- Notification preferences
- Settings management
- Education resources
- Help and support

## Design System

### Color Palette
- **Primary**: Blue (#2563EB)
- **Secondary**: Green (#10B981)
- **Tertiary**: Red (#EF4444)
- **Glucose Levels**: Low (Yellow), Normal (Green), High (Red)
- **Categories**: Meal (Orange), Activity (Green), Medication (Blue), Sleep (Purple)

### Health Data Thresholds
- **Normal Glucose**: 70-180 mg/dL
- **Critical Low**: <54 mg/dL
- **Critical High**: >250 mg/dL
- **Activity Goal**: 60 minutes daily, 420 minutes weekly

### Responsive Breakpoints
- **Mobile**: < 600px (single column layout, bottom navigation)
- **Tablet**: 600-1024px (2-column grid where appropriate)
- **Desktop**: > 1024px (3-column grid, side navigation)

## Getting Started

### Prerequisites
- Flutter SDK ^3.7.2
- Dart SDK ^3.7.2
- Android Studio / Xcode / Visual Studio Code
- Supabase account (optional for demo mode)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd florence
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Edit `lib/config/env.dart` with your Supabase credentials:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

   Note: The app works in demo mode without real Supabase credentials.

4. **Run code generation** (if needed)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

**Android**
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

**Web**
```bash
flutter build web --release
```

**Desktop**
```bash
flutter build windows --release  # Windows
flutter build macos --release    # macOS
flutter build linux --release    # Linux
```

## Configuration

### Environment Variables
Configure in `lib/config/env.dart`:
- `supabaseUrl` - Your Supabase project URL
- `supabaseAnonKey` - Your Supabase anonymous key
- `apiUrl` - Backend API URL
- Feature flags (AI features, offline mode, analytics)

### Constants
Customize app behavior in `lib/config/constants.dart`:
- Health data thresholds
- Activity goals
- Pagination settings
- Cache durations
- Gamification points
- File upload limits

### Theme
Customize appearance in `lib/config/theme.dart`:
- Color schemes (light and dark modes)
- Typography scales
- Component themes
- Spacing and sizing

## Testing

### Demo Mode
The app includes a fully functional demo mode:
- All screens display sample data
- Forms accept any input and show success messages
- Navigation works completely
- No backend required for testing UI/UX

### Running Tests
```bash
flutter test
```

## Security & Privacy

- **Encryption**: All data transmission encrypted via SSL/TLS
- **Authentication**: Secure token-based authentication with Supabase
- **Data Privacy**: HIPAA-compliant data handling practices
- **User Control**: Data export and deletion capabilities
- **Session Management**: Automatic timeout and secure session handling

## Accessibility

- WCAG AA compliant color contrast
- Minimum 44px touch targets
- Screen reader support with semantic labels
- Keyboard navigation (desktop)
- Text scaling support
- High contrast mode support

## Performance Optimization

- Image caching via `cached_network_image`
- Lazy loading for list views
- Pagination for large datasets
- Chart optimization (max 100 data points with auto-sampling)
- Efficient state management with Provider
- Request caching for network calls

## Documentation

Comprehensive documentation available in the `Document/` directory:
- **patient_app_screen_plan.md** (1,670 lines) - Complete UI/UX specification
- **data_logging.md** - Data entry specifications
- **ai_chat.md** - AI assistant specifications
- **profile.md** - User profile specifications
- **foundation_setup_guide.md** - Project setup guide

## Implementation Status

### Completed (11 screens)
- ✅ Authentication (Splash, Login, Register)
- ✅ Dashboard
- ✅ Data Logging (Glucose, Meal, Activity, Medication)
- ✅ Analytics & Trends
- ✅ AI Chat Assistant
- ✅ User Profile

### In Development
- ⏳ Recommendations Feed & Detail
- ⏳ Settings
- ⏳ Notifications
- ⏳ Calendar View
- ⏳ Achievements
- ⏳ Education Library
- ⏳ Help & Support

## Roadmap

**Phase 1**: Core Health Tracking (Complete)
- ✅ Authentication system
- ✅ Dashboard overview
- ✅ Glucose, meal, activity, medication logging
- ✅ Basic analytics

**Phase 2**: Advanced Features (In Progress)
- ⏳ AI-powered recommendations engine
- ⏳ Advanced trend analysis
- ⏳ Gamification system
- ⏳ Educational content library

**Phase 3**: Integration & Collaboration (Planned)
- Healthcare provider portal integration
- Data sharing with clinicians
- Appointment scheduling
- Telemedicine integration

**Phase 4**: Enhanced Intelligence (Planned)
- Predictive analytics
- Advanced pattern recognition
- Personalized meal planning
- Exercise recommendations

## Contributing

This is a university project for COS40005 - Computing Technology Project A.

### Development Guidelines
- Follow Flutter style guide and best practices
- Use Material Design 3 components
- Write comprehensive documentation
- Include tests for new features
- Follow the established project structure

## License

[Specify your license here]

## Team

BioTective Integrated Platform
Third Year First Semester
COS40005 - Computing Technology Project A

## Acknowledgments

- Flutter team for the excellent framework
- Supabase for backend infrastructure
- fl_chart for beautiful data visualizations
- The open-source community

## Support

For issues, questions, or contributions, please refer to the project documentation or contact the development team.

---

**Built with ❤️ using Flutter**
