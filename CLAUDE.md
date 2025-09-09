# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Essential Commands
```bash
# Complete project setup (install dependencies + code generation)
make setup

# Development workflow
make dev                    # Run development server
make clean                 # Clean build artifacts
make build                 # Build APK

# Code quality
make lint                  # Run linting (format + analyze)
make format               # Format code only
make analyze              # Analyze code only

# Testing
make test                 # Run all tests
make test-unit           # Run unit tests only
make test-widget         # Run widget tests only
make coverage            # Run tests with coverage
make coverage-html       # Generate HTML coverage report

# Full CI pipeline
make ci                  # Run complete CI pipeline
```

### Flutter Commands
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

## Project Architecture

### High-Level Structure
- **WhatsApp-like messaging app** with specialized diet/health management features
- **Hybrid architecture**: Drift (local SQLite) as primary database + Firebase for sync
- **Cost-optimized**: UI reads from local DB, Firebase syncs in background
- **Provider pattern**: State management using Provider package

### Key Architectural Components

#### Database Layer (Drift-based)
- **Primary Database**: Drift (SQLite) with 16+ tables
- **Sync Layer**: Firebase Firestore for cloud synchronization
- **Central Service**: `DriftService` provides unified API (replaces legacy Isar)
- **Auto-generated**: Drift DAOs and companions via `build_runner`

#### Core Service Architecture
```
Services (40+ services)
├── Auth & User Management
├── Messaging & Chat System  
├── Diet & Health Management
├── Firebase Sync Services
├── Media & File Handling
└── Background Services
```

#### Key Services
- `DriftService`: Central database abstraction layer
- `OptimizedChatProvider`: Main UI state management
- `FirebaseBackgroundSyncService`: Cost-optimized sync
- `ConnectionAwareSyncService`: Smart data usage
- `ContactsManager`: Centralized contact management
- `StepCounterService`: Health tracking
- `MediaCacheManager`: Media optimization

### Domain-Specific Features

#### Diet Management System
- **Diet Packages**: Structured diet programs with BMI-based selection
- **Automatic Delivery**: PDF generation and scheduled sending
- **Bulk Upload**: Directory-based package creation
- **BMI Engine**: Automatic diet file selection based on user metrics

#### Messaging System
- **WhatsApp-like UI**: Familiar chat interface
- **Media Support**: Images, videos, documents, audio, location
- **Group Management**: Full group chat functionality
- **Story System**: 24-hour disappearing content
- **Tag System**: Chat organization for dietitians

#### Health Tracking
- **BMI Calculations**: Age-based ideal weight formulas
- **Progress Tracking**: Weight graphs with fl_chart
- **Step Counter**: Daily activity monitoring
- **Health Dashboard**: Comprehensive health analytics

### Data Flow Patterns

#### Hybrid Database Strategy
1. **UI Layer** → Always reads from Drift (local)
2. **Background Sync** → Firebase ↔ Drift synchronization
3. **Cost Optimization** → Minimal Firebase reads (cache-first)
4. **Offline Support** → Full functionality without internet

#### State Management
- **Providers**: Main UI state (chat, stories, tags, groups)
- **Services**: Business logic and data operations
- **Models**: Data structures with factory constructors
- **Database**: Persistence layer with automatic sync

### Code Generation Requirements

#### Drift Database
- **Generate after schema changes**: `make setup` or build_runner
- **Database file**: `lib/database/drift/database.dart`
- **Generated files**: `**/*.g.dart` (excluded from git)

#### Mock Generation
- **Test mocks**: Generated via mockito for `test/**/*.dart`
- **Run**: `flutter packages pub run build_runner build`

### Testing Strategy

#### Test Configuration
- **Golden Tests**: Using `golden_toolkit` for UI consistency
- **Test Devices**: Phone, iPhone 11, Tablet Portrait
- **Coverage**: 70% threshold enforced
- **Test Config**: Custom `flutter_test_config.dart`

#### Test Organization
```
test/
├── unit/          # Unit tests (services, models, utilities)
├── widget/        # Widget tests (UI components) 
└── integration/   # Integration tests (end-to-end flows)
```

## Project-Specific Guidelines

### Database Schema Changes
1. Modify table definitions in `lib/database/drift/tables/`
2. Run `make setup` to regenerate code
3. Update `DriftService` converters if needed
4. Test with `make test` before committing

### Firebase Cost Optimization
- **Never read directly from Firebase in UI code**
- Use `FirebaseBackgroundSyncService` for all sync operations
- Leverage Drift as single source of truth for UI
- Cache Firebase data aggressively

### Diet System Development
- Use `DietAssignmentEngine` for business logic
- BMI calculations via `BMICalculationEngine`  
- PDF generation through `PDFGenerationService`
- File parsing via `DocxParserService`

### Message System Architecture
- `OptimizedChatProvider` for UI state
- `MessageService` for message operations
- Media handling via `MediaService` + `MediaCacheManager`
- Background sync via dedicated services

### Performance Considerations
- **Lazy Loading**: Services initialize in background
- **Connection Aware**: Smart sync based on network status
- **Media Optimization**: Automatic compression and caching  
- **Battery Optimization**: Background service management

### Deployment Pipeline
- **Makefile**: Use `make ci` for full validation
- **Firebase**: Configured for staging/production
- **Code Quality**: Enforced via `analysis_options.yaml`
- **Coverage**: HTML reports generated automatically

## Important Notes

### Code Generation Dependencies
- Run `make setup` after pulling schema changes
- Generated files are git-ignored (never commit `*.g.dart`)
- Build failures often resolve with clean + regenerate

### Firebase Configuration
- Development: Debug certificates enabled
- Production: App Check configured for security
- Offline-first: App works without internet connection

### State Management Pattern  
- Providers for UI state
- Services for business logic  
- Models with factory constructors
- Database as single source of truth

### Testing Requirements
- Widget tests must use golden toolkit configuration
- Unit tests should mock external dependencies
- Coverage threshold enforced at 70%
- Integration tests for critical user flows

## Claude Davranış Kuralları

### Zorunlu Kurallar (DAIMA UY)
1. **Türkçe İletişim**: Tüm cevaplar, açıklamalar ve kullanıcı etkileşimleri Türkçe olmalıdır
2. **Context7 Kullanımı**: Kod parçacıklarını kaydetmek, organize etmek ve yeniden kullanmak için daima Context7 MCP servisini kullanın
3. **Paket Güncelliği**: Flutter projesine yeni paket eklerken:
   - MUTLAKA https://pub.dev/ sitesinden en güncel sürümü kontrol edin
   - WebFetch tool'u kullanarak pub.dev'den güncel sürüm bilgisini alın
   - pubspec.yaml'a eklemeden önce sürüm uyumluluğunu doğrulayın

### Context7 Kullanım Zorunlulukları
- Yeni kod parçacığı yazıldığında Context7'ye kaydedin
- Benzer işlevsellik gerektiğinde önce Context7'den arayın
- Projeler arası kod paylaşımı için Context7'yi kullanın
- Utility fonksiyonları ve widget'ları Context7'de organize edin

### Paket Yönetimi Protokolü
- Paket eklemeden önce: `WebFetch https://pub.dev/packages/[paket-adı]` kullanın
- En güncel sürümü ve bağımlılıkları kontrol edin
- Paket uyumluluğunu Flutter SDK versiyonu ile doğrulayın
- pubspec.yaml güncellemesinden sonra `make setup` çalıştırın

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
