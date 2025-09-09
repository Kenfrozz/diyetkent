# DiyetKent - Flutter Messaging & Diet Management App

DiyetKent is a WhatsApp-like messaging application with specialized diet and health management features, built with Flutter.

## 🚀 Features

### 📱 Messaging System
- **WhatsApp-like UI**: Familiar chat interface
- **Media Support**: Images, videos, documents, audio, location sharing
- **Group Management**: Full group chat functionality with permissions
- **Story System**: 24-hour disappearing content
- **Tag System**: Chat organization for dietitians
- **Message Forwarding**: Send messages to multiple chats
- **Reply System**: Reply to specific messages

### 🥗 Diet Management
- **Diet Packages**: Structured diet programs with BMI-based selection
- **Automatic Delivery**: PDF generation and scheduled sending
- **Bulk Upload**: Directory-based package creation
- **BMI Engine**: Automatic diet file selection based on user metrics
- **Progress Tracking**: Weight graphs and health analytics

### 📊 Health Tracking
- **BMI Calculations**: Age-based ideal weight formulas
- **Step Counter**: Daily activity monitoring  
- **Health Dashboard**: Comprehensive health analytics
- **Progress Graphs**: Visual tracking with fl_chart

## 🏗️ Architecture

### Database Architecture
- **Primary Database**: Drift (SQLite) with 16+ tables
- **Sync Layer**: Firebase Firestore for cloud synchronization
- **Cost-Optimized**: UI reads from local DB, Firebase syncs in background
- **Offline Support**: Full functionality without internet

### Key Services
- `DriftService`: Central database abstraction layer
- `OptimizedChatProvider`: Main UI state management
- `FirebaseBackgroundSyncService`: Cost-optimized sync
- `ConnectionAwareSyncService`: Smart data usage
- `ContactsManager`: Centralized contact management
- `StepCounterService`: Health tracking
- `MediaCacheManager`: Media optimization

## 🛠️ Development

### Prerequisites
- Flutter SDK (>=3.3.0)
- Firebase project setup
- Android/iOS development environment

### Setup
```bash
# Install dependencies and generate code
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Development Commands
```bash
# Code generation (required after schema changes)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Development
flutter run
flutter analyze
flutter test

# Build
flutter build apk --debug
flutter build apk --release
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Key Dependencies

### Core
- **flutter**: UI framework
- **drift**: SQLite database ORM
- **firebase_core**: Firebase integration
- **cloud_firestore**: Cloud database
- **firebase_auth**: Authentication
- **firebase_storage**: File storage
- **provider**: State management

### Features
- **fl_chart**: Health progress charts
- **image_picker**: Camera and gallery access
- **geolocator**: Location services
- **audioplayers**: Audio message playback
- **record**: Audio recording
- **file_picker**: Document selection
- **share_plus**: Content sharing

## 🔒 Security Features

- **Firebase App Check**: App integrity verification
- **Offline-first**: App works without internet connection
- **Cost-optimized**: Minimal Firebase reads (cache-first approach)
- **Media Optimization**: Automatic compression and caching

## 📱 Platform Support

- ✅ Android
- ✅ iOS (configuration required)
- 🚧 Web (limited features)

## 🧪 Testing Strategy

- **Unit Tests**: Services, models, utilities
- **Widget Tests**: UI components with golden toolkit
- **Integration Tests**: End-to-end user flows
- **Coverage**: 70% threshold enforced

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Kenfroz**
- GitHub: [@Kenfroz](https://github.com/Kenfroz)

## 📞 Support

For support and questions, please open an issue on GitHub.

---

*Built with ❤️ using Flutter and Firebase*