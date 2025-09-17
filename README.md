# Saint Demiana Children - Flutter Frontend

A Flutter application for Saint Demiana Children's Church data collection and management.

## Features

- **User Management**: Complete user registration and profile management
- **Role-based Access**: Support for Admin (Khadem) and Member (Makhdoum) roles
- **Attendance Tracking**: Record and manage attendance for church activities
- **Multi-platform**: Runs on Android, iOS, and Web
- **Arabic Support**: Full RTL support for Arabic language
- **Modern UI**: Beautiful, responsive design with Material Design 3

## Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Node.js (for backend API)

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd SaintDemianaChildren
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure the API endpoint in `lib/core/config/app_config.dart`:
```dart
static const String developmentUrl = 'http://localhost:3000';
```

4. Run the application:
```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## Project Structure

```
lib/
├── core/                 # Core functionality
│   ├── config/          # App configuration
│   ├── constants/       # App constants
│   ├── services/        # API and logging services
│   └── theme/           # App theming
├── models/              # Data models
├── providers/           # State management
├── screens/             # UI screens
├── widgets/             # Reusable widgets
└── main.dart           # App entry point
```

## Configuration

### API Configuration
Update the API URL in `lib/core/config/app_config.dart`:
```dart
static const String developmentUrl = 'http://your-backend-url:3000';
```

### Environment Setup
- Development: Set `isDevelopment = true`
- Production: Set `isDevelopment = false`

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Dependencies

- **provider**: State management
- **go_router**: Navigation
- **dio**: HTTP client
- **shared_preferences**: Local storage
- **image_picker**: Image selection
- **google_fonts**: Typography
- **flutter_svg**: SVG support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support, please contact the development team or create an issue in the repository.