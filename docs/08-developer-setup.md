# 🛠️ DiyetKent - Developer Setup ve Deployment Rehberi

## 📋 İçindekiler
- [Development Environment Setup](#development-environment-setup)
- [Project Setup](#project-setup)
- [Firebase Configuration](#firebase-configuration)
- [Code Generation](#code-generation)
- [Testing Strategy](#testing-strategy)
- [Build and Deploy](#build-and-deploy)
- [CI/CD Pipeline](#ci-cd-pipeline)
- [Troubleshooting](#troubleshooting)

---

## 💻 Development Environment Setup

### 📋 **Gerekli Araçlar ve Versiyonlar**

#### **🎯 Minimum Gereksinimler**
```yaml
Flutter SDK: >=3.3.0 <4.0.0
Dart SDK: >=3.3.0 <4.0.0
Java/OpenJDK: 11 veya üstü
Xcode: 14+ (iOS development için)
Android Studio: 2022.3+ (Arctic Fox)
VS Code: Latest (önerilen)
Git: 2.30+
Firebase CLI: 12.0+
```

#### **🖥️ İşletim Sistemi Desteği**
| Platform | Status | Notlar |
|----------|--------|--------|
| **Windows 10/11** | ✅ Tam Destek | Ana geliştirme ortamı |
| **macOS** | ✅ Tam Destek | iOS build için gerekli |
| **Linux (Ubuntu)** | ✅ Destek | Android-only |

### 📦 **Flutter ve Dart SDK Kurulumu**

#### **Windows (Chocolatey ile)**
```powershell
# Chocolatey kurulu değilse önce kurun
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Flutter SDK'yı kurun
choco install flutter

# Git kurulumu
choco install git

# Android Studio kurulumu
choco install androidstudio

# VS Code kurulumu
choco install vscode
```

#### **macOS (Homebrew ile)**
```bash
# Homebrew kurulu değilse önce kurun
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter SDK'yı kurun
brew install --cask flutter

# Git kurulumu
brew install git

# Xcode Command Line Tools
xcode-select --install
```

#### **Linux (Manuel Kurulum)**
```bash
# Dependencies
sudo apt update
sudo apt install git curl unzip xz-utils zip libglu1-mesa

# Flutter SDK
cd ~/
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Android Studio kurulumu için snap
sudo snap install android-studio --classic
```

### ⚙️ **IDE Konfigürasyonu**

#### **VS Code Extensions (Önerilen)**
```json
{
  "recommendations": [
    "Dart-Code.flutter",
    "Dart-Code.dart-code", 
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "ms-vscode.test-adapter-converter",
    "formulahendry.code-runner",
    "alefragnani.project-manager",
    "gruntfuggly.todo-tree"
  ]
}
```

#### **VS Code Ayarları (.vscode/settings.json)**
```json
{
  "dart.flutterSdkPath": "/flutter",
  "dart.enableSdkFormatter": true,
  "dart.lineLength": 120,
  "dart.runPubGetOnPubspecChanges": true,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  "files.associations": {
    "*.dart": "dart"
  }
}
```

#### **Android Studio Plugin'leri**
- Flutter Plugin
- Dart Plugin  
- Git Integration
- Markdown Support
- Firebase Plugin
- Device File Explorer

### 🔧 **Flutter Doctor Kontrolü**
Development ortamının hazır olduğundan emin olmak için:

```bash
flutter doctor -v
```

**✅ Başarılı Output Örneği:**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.16.0, on Microsoft Windows [Version 10.0.22631.2715], locale tr-TR)
[✓] Windows Version (Installed version of Windows is version 10 or higher)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.7.4)
[✓] Android Studio (version 2022.3)
[✓] VS Code (version 1.84.2)
[✓] Connected device (3 available)
[✓] Network resources
```

---

## 🚀 Project Setup

### 📥 **Repository Clone**

#### **1. Repository'yi Clone Edin**
```bash
# Repository'yi clone edin
git clone https://github.com/Kenfrozz/diyetkent.git
cd diyetkent

# Branch'leri kontrol edin
git branch -a

# Ana branch'e geçin
git checkout main
```

#### **2. Development Branch Oluşturun**
```bash
# Kendi development branch'inizi oluşturun
git checkout -b feature/your-feature-name

# Veya bug fix için
git checkout -b fix/issue-description
```

### 📦 **Dependencies ve Setup**

#### **Makefile ile Hızlı Setup (Önerilen)**
```bash
# Tüm setup işlemlerini otomatik yap
make setup

# Bu komut şunları yapar:
# - flutter pub get
# - flutter packages pub run build_runner build --delete-conflicting-outputs
# - Firebase kurulumu kontrolü
```

#### **Manuel Setup**
```bash
# 1. Dependencies yükle
flutter pub get

# 2. Code generation çalıştır
flutter packages pub run build_runner build --delete-conflicting-outputs

# 3. Firebase CLI kontrol
firebase --version

# 4. Project doğrula
flutter analyze
```

### 📁 **Proje Yapısını Anlama**

#### **Ana Dizin Yapısı**
```
diyetkent/
├── 📁 android/              # Android specific configs
├── 📁 ios/                  # iOS specific configs  
├── 📁 lib/                  # Main Dart code
│   ├── database/            # Drift database layer
│   ├── models/              # Data models
│   ├── pages/               # UI screens
│   ├── providers/           # State management
│   ├── services/            # Business logic
│   ├── utils/               # Helper utilities
│   └── widgets/             # Custom widgets
├── 📁 test/                 # Test files
├── 📁 docs/                 # Documentation
├── 📄 pubspec.yaml          # Dependencies
├── 📄 analysis_options.yaml # Lint rules
├── 📄 Makefile             # Development commands
└── 📄 firebase.json        # Firebase config
```

#### **Core Directories Detayı**
```
lib/
├── main.dart                    # App entry point
├── database/
│   ├── drift_service.dart       # Main DB abstraction
│   └── drift/
│       ├── database.dart        # Database class
│       ├── tables/              # Table definitions
│       └── daos/               # Data Access Objects
├── services/ (52 services)
│   ├── auth_service.dart
│   ├── message_service.dart
│   ├── diet_assignment_engine.dart
│   └── ... (other services)
└── providers/
    ├── optimized_chat_provider.dart
    ├── tag_provider.dart
    └── ... (other providers)
```

---

## 🔥 Firebase Configuration

### 🔑 **Firebase Project Setup**

#### **1. Firebase Console'dan Proje Oluşturun**
1. https://console.firebase.google.com adresine gidin
2. "Add project" tıklayın
3. Project adı: `diyetkent-dev` (development için)
4. Analytics'i enable edin
5. Project'i oluşturun

#### **2. Firebase CLI Authentication**
```bash
# Firebase CLI kurulumu (npm gerekli)
npm install -g firebase-tools

# Firebase'e login olun
firebase login

# Project'i initialize edin
firebase init

# Aşağıdaki özellikler seçin:
# - Firestore
# - Functions  
# - Storage
# - Hosting (dokümantasyon için)
```

#### **3. Android App Ekleme**
```bash
# Android app ekle
firebase apps:create android com.example.diyetkent

# google-services.json dosyasını indirin
firebase apps:sdkconfig android com.example.diyetkent

# Dosyayı android/app/ klasörüne kopyalayın
cp google-services.json android/app/
```

#### **4. iOS App Ekleme (Mac gerekli)**
```bash
# iOS app ekle
firebase apps:create ios com.example.diyetkent

# GoogleService-Info.plist indirin
firebase apps:sdkconfig ios com.example.diyetkent

# Dosyayı iOS projesine ekleyin (Xcode ile)
```

### 🔧 **Firebase Configuration Files**

#### **Firebase Rules (firestore.rules)**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Development ortamı için açık kurallar
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Production için sıkı kurallar
    // match /users/{userId} {
    //   allow read, write: if request.auth != null && request.auth.uid == userId;
    // }
  }
}
```

#### **Storage Rules (storage.rules)**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Development için açık erişim
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### **Firebase Security Keys (.env)**
```bash
# .env dosyası oluşturun (git'e eklemeyin)
FIREBASE_API_KEY=your_api_key_here
FIREBASE_AUTH_DOMAIN=diyetkent-dev.firebaseapp.com
FIREBASE_PROJECT_ID=diyetkent-dev
FIREBASE_STORAGE_BUCKET=diyetkent-dev.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID=1:123456789:android:abcdef123456
```

### ⚙️ **Firebase Initialization Kodu**

#### **Firebase Options (firebase_options.dart)**
```bash
# Firebase options dosyası oluştur
flutter packages pub run build_runner build

# FlutterFire CLI ile otomatik config
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## 🏗️ Code Generation

### 🔄 **Drift Database Generation**

#### **Build Runner Commands**
```bash
# İlk code generation
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch mode (development sırasında)
flutter packages pub run build_runner watch

# Sadece temizle
flutter packages pub run build_runner clean
```

#### **Generated Files (.gitignore'da)**
```gitignore
# Generated files
**/*.g.dart
**/*.freezed.dart
**/*.mocks.dart

# Database files
**/database.g.dart
**/database.drift.dart
```

### 📝 **Makefile Commands**

#### **Development Commands**
```bash
# Temel setup
make setup          # Dependencies + code generation
make clean          # Clean project
make dev            # Run development server

# Code quality
make format         # Format code
make analyze        # Analyze code
make lint           # Format + analyze

# Testing  
make test           # Run all tests
make test-unit      # Unit tests only
make test-widget    # Widget tests only
make coverage       # Test coverage
make coverage-html  # HTML coverage report

# Build
make build          # Build APK
make build-ios      # Build iOS (Mac only)

# CI/CD
make ci             # Full CI pipeline
```

### 🧪 **Mock Generation**
```bash
# Test mocks generate
flutter packages pub run build_runner build --delete-conflicting-outputs

# Mockito annotations kullanıyorsanız
@GenerateMocks([DriftService, AuthService])
void main() {
  // Test kodları
}
```

---

## 🧪 Testing Strategy

### 📊 **Test Türleri ve Organizasyon**

#### **Test Directory Structure**
```
test/
├── 📁 unit/                    # Unit tests
│   ├── services/              # Service tests
│   ├── models/                # Model tests
│   └── utils/                 # Utility tests
├── 📁 widget/                  # Widget tests
│   ├── pages/                 # Page tests
│   └── widgets/               # Custom widget tests
├── 📁 integration/             # Integration tests
│   └── app_test.dart          # E2E tests
└── flutter_test_config.dart   # Test configuration
```

#### **Test Configuration (flutter_test_config.dart)**
```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      await loadAppFonts();
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      enableRealShadows: true,
      defaultDevices: const [
        Device.phone,
        Device.iphone11,
        Device.tabletPortrait,
      ],
    ),
  );
}
```

### 🔬 **Unit Testing**

#### **Service Test Örneği**
```dart
// test/unit/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:diyetkent/services/auth_service.dart';

import '../mocks.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    
    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
    });
    
    test('should send SMS verification', () async {
      // Arrange
      const phoneNumber = '+905551234567';
      when(mockFirebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: any,
        verificationCompleted: any,
        verificationFailed: any,
        codeSent: any,
      )).thenAnswer((_) async {
        // Mock implementation
      });
      
      // Act
      final result = await AuthService.sendSMSVerification(phoneNumber);
      
      // Assert
      expect(result, isNotEmpty);
      verify(mockFirebaseAuth.verifyPhoneNumber(phoneNumber: phoneNumber));
    });
  });
}
```

#### **Model Test Örneği**
```dart
// test/unit/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:diyetkent/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('should create user model with valid data', () {
      // Arrange
      const userId = 'test_user_123';
      const name = 'Test User';
      const phoneNumber = '+905551234567';
      
      // Act
      final user = UserModel.create(
        userId: userId,
        name: name,
        phoneNumber: phoneNumber,
      );
      
      // Assert
      expect(user.userId, equals(userId));
      expect(user.name, equals(name));
      expect(user.phoneNumber, equals(phoneNumber));
    });
    
    test('should serialize to and from JSON', () {
      // Arrange
      final user = UserModel.create(
        userId: 'test_123',
        name: 'Test User',
        phoneNumber: '+905551234567',
      );
      
      // Act
      final json = user.toJson();
      final deserializedUser = UserModel.fromJson(json);
      
      // Assert
      expect(deserializedUser.userId, equals(user.userId));
      expect(deserializedUser.name, equals(user.name));
    });
  });
}
```

### 🎨 **Widget Testing**

#### **Widget Test Örneği (Golden Test)**
```dart
// test/widget/widgets/chat_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:diyetkent/widgets/chat_tile.dart';
import 'package:diyetkent/models/chat_model.dart';

void main() {
  group('ChatTile Widget Tests', () {
    testGoldens('should display chat tile correctly', (tester) async {
      // Arrange
      final chat = ChatModel.create(
        chatId: 'test_chat_123',
        isGroup: false,
        otherUserName: 'Dr. Ayşe Kaya',
        lastMessage: 'Merhaba, nasılsınız?',
        lastMessageTime: DateTime.now(),
        unreadCount: 2,
      );
      
      // Act
      await tester.pumpWidgetBuilder(
        ChatTile(chat: chat),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            primaryColor: const Color(0xFF00796B),
          ),
        ),
      );
      
      // Assert
      await screenMatchesGolden(tester, 'chat_tile_with_unread');
    });
    
    testWidgets('should handle tap events', (tester) async {
      // Arrange
      bool tapped = false;
      final chat = ChatModel.create(
        chatId: 'test_chat',
        isGroup: false,
        otherUserName: 'Test User',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatTile(
              chat: chat,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.byType(ChatTile));
      
      // Assert
      expect(tapped, isTrue);
    });
  });
}
```

### 🔗 **Integration Testing**

#### **E2E Test Örneği**
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:diyetkent/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('DiyetKent E2E Tests', () {
    testWidgets('should complete login flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();
      
      // Find phone number input
      final phoneInput = find.byKey(const Key('phone_input'));
      expect(phoneInput, findsOneWidget);
      
      // Enter phone number
      await tester.enterText(phoneInput, '+905551234567');
      await tester.pump();
      
      // Tap send SMS button
      final sendButton = find.byKey(const Key('send_sms_button'));
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      
      // Verify OTP screen appears
      expect(find.byKey(const Key('otp_input')), findsOneWidget);
      
      // Enter mock OTP (in test environment)
      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.pump();
      
      // Tap verify button
      await tester.tap(find.byKey(const Key('verify_button')));
      await tester.pumpAndSettle();
      
      // Verify main screen loads
      expect(find.byKey(const Key('main_screen')), findsOneWidget);
    });
  });
}
```

### 📊 **Test Coverage**

#### **Coverage Commands**
```bash
# Coverage report oluştur
make coverage

# HTML coverage report
make coverage-html

# Coverage threshold kontrolü
flutter test --coverage
lcov --summary coverage/lcov.info

# Specific package coverage
flutter test --coverage test/unit/services/
```

#### **Coverage Configuration**
```yaml
# analysis_options.yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.mocks.dart"
    - "lib/database/drift/database.dart"
    - "test/**"

linter:
  rules:
    prefer_coverage_report_title: true
```

---

## 🚀 Build and Deploy

### 📱 **Android Build**

#### **Debug Build**
```bash
# Debug APK
flutter build apk --debug

# Debug Bundle (Play Store için)
flutter build appbundle --debug

# Specific flavor
flutter build apk --debug --flavor development
```

#### **Release Build**
```bash
# Release APK
flutter build apk --release

# Release Bundle (önerilen)
flutter build appbundle --release

# Build number ile
flutter build apk --release --build-number=1
```

#### **Android Signing Setup**
```bash
# Keystore oluştur
keytool -genkey -v -keystore ~/diyetkent-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias diyetkent

# android/key.properties oluştur
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=diyetkent
storeFile=/path/to/diyetkent-key.jks
```

#### **android/app/build.gradle**
```gradle
android {
    // ... diğer konfigürasyonlar
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 🍎 **iOS Build (macOS gerekli)**

#### **Prerequisites**
```bash
# Xcode Command Line Tools
xcode-select --install

# CocoaPods kurulumu
sudo gem install cocoapods

# iOS dependencies
cd ios && pod install
```

#### **Development Build**
```bash
# iOS Simulator için
flutter build ios --debug --simulator

# iOS Device için (development profile gerekli)
flutter build ios --debug
```

#### **Release Build**
```bash
# Release build
flutter build ios --release

# Archive için (App Store)
flutter build ipa --release
```

#### **iOS Signing ve Provisioning**
1. Apple Developer hesabı gerekli
2. Xcode'da signing setup
3. Provisioning profile konfigürasyonu
4. App Store Connect setup

### 🌐 **Web Build**

#### **Web Build Commands**
```bash
# Debug build
flutter build web --debug

# Release build
flutter build web --release

# Base href ile
flutter build web --base-href /diyetkent/

# PWA features ile
flutter build web --pwa-strategy offline-first
```

#### **Web Deployment**
```bash
# Firebase Hosting
firebase deploy --only hosting

# GitHub Pages
# build/web klasörünü gh-pages branch'e push edin

# Netlify
# build/web klasörünü Netlify'a yükleyin
```

---

## 🔄 CI/CD Pipeline

### 🐙 **GitHub Actions Workflow**

#### **.github/workflows/ci.yml**
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Get dependencies
      run: flutter pub get
      
    - name: Code generation
      run: flutter packages pub run build_runner build --delete-conflicting-outputs
      
    - name: Analyze code
      run: flutter analyze
      
    - name: Run tests
      run: flutter test --coverage
      
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
        
  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '11'
        
    - name: Get dependencies
      run: flutter pub get
      
    - name: Code generation
      run: flutter packages pub run build_runner build --delete-conflicting-outputs
      
    - name: Build APK
      run: flutter build apk --release
      
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
        
  deploy-firebase:
    needs: [test, build-android]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install Firebase CLI
      run: npm install -g firebase-tools
      
    - name: Deploy Firestore Rules
      run: firebase deploy --only firestore:rules --token ${{ secrets.FIREBASE_TOKEN }}
      
    - name: Deploy Cloud Functions
      run: firebase deploy --only functions --token ${{ secrets.FIREBASE_TOKEN }}
```

#### **Secrets Configuration**
GitHub Repository Settings → Secrets'a ekleyin:
```
FIREBASE_TOKEN: Firebase CI token
ANDROID_KEYSTORE: Base64 encoded keystore
KEYSTORE_PASSWORD: Keystore password
KEY_PASSWORD: Key password
KEY_ALIAS: Key alias
```

### 🔧 **Automated Workflows**

#### **Pre-commit Hooks**
```bash
# Git hooks kurulumu
make hooks

# Manuel pre-commit hook
#!/bin/sh
echo "Running pre-commit checks..."
flutter analyze
if [ $? -ne 0 ]; then
  echo "❌ Flutter analyze failed"
  exit 1
fi

flutter test --no-coverage
if [ $? -ne 0 ]; then
  echo "❌ Tests failed"
  exit 1
fi

echo "✅ All checks passed"
```

#### **Automated Testing**
```yaml
# .github/workflows/test.yml
name: Automated Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  nightly-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Run comprehensive tests
      run: |
        flutter pub get
        flutter packages pub run build_runner build --delete-conflicting-outputs
        flutter test --coverage
        flutter test integration_test/
        
    - name: Notify on failure
      if: failure()
      uses: 8398a7/action-slack@v3
      with:
        status: failure
        channel: '#dev-alerts'
```

---

## 🛠️ Troubleshooting

### ❌ **Yaygın Sorunlar ve Çözümler**

#### **Flutter/Dart Sorunları**

**❌ Problem**: "Flutter SDK not found"
```bash
# Çözüm 1: PATH kontrol
echo $PATH
which flutter

# Çözüm 2: Flutter yeniden kur
rm -rf flutter/
git clone https://github.com/flutter/flutter.git -b stable

# Çözüm 3: Doctor çalıştır
flutter doctor -v
```

**❌ Problem**: "Build runner conflicts"
```bash
# Çözüm: Cache temizle ve yeniden build
flutter clean
flutter pub get
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**❌ Problem**: "Android license not accepted"
```bash
# Çözüm: Android licenses kabul et
flutter doctor --android-licenses

# Veya SDK Manager ile
$ANDROID_HOME/tools/bin/sdkmanager --licenses
```

#### **Firebase Sorunları**

**❌ Problem**: "Firebase project not found"
```bash
# Çözüm 1: Firebase login kontrolü
firebase login
firebase projects:list

# Çözüm 2: Project initialize
firebase use --add your-project-id

# Çözüm 3: Config dosyalarını kontrol et
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist
```

**❌ Problem**: "Firestore rules deployment failed"
```bash
# Çözüm 1: Rules syntax kontrol
firebase firestore:rules:get

# Çözüm 2: Manuel deployment
firebase deploy --only firestore:rules

# Çözüm 3: Permissions kontrol
firebase projects:list
firebase use your-project-id
```

#### **Build Sorunları**

**❌ Problem**: "Android build failed - multidex"
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

**❌ Problem**: "iOS build failed - CocoaPods"
```bash
# Çözüm 1: Pod temizle ve yeniden kur
cd ios
rm -rf Pods/
rm Podfile.lock
pod install

# Çözüm 2: Pod repo güncelle  
pod repo update
pod install

# Çözüm 3: Flutter clean
cd ..
flutter clean
flutter pub get
cd ios && pod install
```

#### **Testing Sorunları**

**❌ Problem**: "Golden test failures"
```bash
# Çözüm 1: Golden'ları güncelle
flutter test --update-goldens

# Çözüm 2: Specific test güncelle
flutter test test/widget/specific_test.dart --update-goldens

# Çözüm 3: Font loading problemi
# flutter_test_config.dart'ta loadAppFonts() ekleyin
```

**❌ Problem**: "Integration test timeouts"
```dart
// Çözüm: Timeout süresini artır
testWidgets('test name', (tester) async {
  tester.binding.defaultTestTimeout = Timeout(Duration(minutes: 5));
  // Test code
}, timeout: Timeout(Duration(minutes: 5)));
```

### 📊 **Performance Debugging**

#### **Memory Leaks**
```bash
# Flutter Inspector kullan
flutter run --debug
# DevTools'da Memory tab

# Observatory kullan
flutter run --debug --observatory-port=8080
```

#### **Build Size Analysis**
```bash
# APK size analysis
flutter build apk --analyze-size

# Bundle size analysis  
flutter build appbundle --analyze-size

# Web bundle analysis
flutter build web --analyze-size
```

### 🔧 **Development Tools**

#### **Debugging Commands**
```bash
# Hot reload ile debug
flutter run --debug

# Profile mode
flutter run --profile

# Release mode test
flutter run --release

# Specific device
flutter run -d android
flutter run -d chrome

# Verbose logging
flutter run --verbose
```

#### **Profiling Tools**
```bash
# Performance profiling
flutter run --profile --trace-startup

# Memory profiling
flutter run --profile --trace-systrace

# Network profiling  
flutter run --debug --observatory-port=8080
```

---

## 📚 **Ek Kaynaklar**

### 📖 **Dokümantasyon Linkleri**
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language](https://dart.dev/guides)
- [Firebase Flutter](https://firebase.google.com/docs/flutter/setup)
- [Drift Documentation](https://drift.simonbinder.eu/)

### 🛠️ **Yararlı Araçlar**
- [Flutter Inspector](https://flutter.dev/docs/development/tools/inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)

### 🎓 **Learning Resources**
- [Flutter Codelabs](https://codelabs.developers.google.com/codelabs/flutter-codelab-first#0)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Firebase Flutter Samples](https://github.com/firebase/flutterfire/tree/master/packages)

---

**🎉 Development environment hazır! Kodlamaya başlayabilirsiniz!**

**Son Güncelleme**: 2024-01-11  
**Doküman Versiyonu**: 1.0.0  
**Flutter Version**: 3.16.0