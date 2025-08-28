# Personal Diary App

A comprehensive, feature-rich personal diary application built with Flutter and Firebase, designed to help users capture, organize, and reflect on their daily experiences with multimedia support, intelligent search, and personalized themes.

## 🌟 Features

### Core Functionality
- **Diary Entries**: Create, edit, and delete personal diary entries with rich text content
- **Calendar View**: Navigate through entries using an intuitive calendar interface with real-time updates
- **Search & Discovery**: Advanced search functionality with tags and content-based filtering
- **User Authentication**: Secure signup, login, and profile management system

### Multimedia Integration
- **Image Support**: Add photos from gallery or capture new images with camera
- **Audio Recording**: Record voice notes and audio entries with transcription support
- **Video Support**: Upload and play video content within diary entries
- **File Management**: Organize and manage various media types efficiently

### Smart Features
- **Location & Weather**: Automatic location detection and weather information for each entry
- **Emotional Tracking**: Rate entries on a 1-5 emotional scale (Very Happy to Very Sad)
- **Tagging System**: Organize entries with custom tags for better categorization
- **Voice-to-Text**: Transcribe audio recordings using AssemblyAI integration

### User Experience
- **Theme Customization**: Multiple color themes with immediate visual feedback
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Real-time Updates**: Live synchronization across all devices
- **Offline Support**: Cached data for improved performance and offline access

### Security & Privacy
- **User Isolation**: Each user can only access their own data
- **Secure Authentication**: Firebase Authentication with proper security rules
- **Data Privacy**: Encrypted data transmission and storage

## 🛠️ Tech Stack

### Frontend
- **Flutter**: Cross-platform mobile app development framework
- **Dart**: Programming language for Flutter applications
- **Provider**: State management solution for Flutter

### Backend & Database
- **Firebase Firestore**: NoSQL cloud database for real-time data synchronization
- **Firebase Authentication**: User authentication and management
- **Firebase Storage**: Cloud storage for media files (images, audio, video)

### External Services
- **AssemblyAI**: AI-powered audio transcription service
- **OpenWeatherMap API**: Weather information integration
- **Geolocation Services**: Location detection and reverse geocoding

### Development Tools
- **Android Studio / VS Code**: IDE support
- **Firebase CLI**: Command-line tools for Firebase management
- **Flutter CLI**: Flutter development and build tools

## 🏗️ System Architecture

### Frontend Architecture
```
lib/
├── main.dart                 # App entry point and configuration
├── screens/                  # UI screens and pages
│   ├── home_screen.dart     # Main dashboard with recent entries
│   ├── new_entry_screen.dart # Diary entry creation/editing
│   ├── calendar_screen.dart # Calendar view of entries
│   ├── search_screen.dart   # Search and discovery interface
│   ├── profile_screen.dart  # User profile and settings
│   ├── login_screen.dart    # User authentication
│   └── signup_screen.dart   # User registration
├── services/                 # Business logic and external integrations
│   ├── auth_service.dart    # Authentication management
│   ├── firestore_service.dart # Database operations
│   ├── storage_service.dart # File storage operations
│   ├── theme_service.dart   # Theme management
│   ├── weather_service.dart # Weather API integration
│   ├── location_service.dart # Location services
│   ├── voice_service.dart   # Audio recording and playback
│   ├── assemblyai_service.dart # AI transcription
│   └── search_service.dart  # Search functionality
├── models/                   # Data models
│   └── diary_entry.dart     # Diary entry data structure
├── widgets/                  # Reusable UI components
└── utils/                    # Utility functions and helpers
```

### Backend Architecture
- **Firebase Firestore**: Document-based NoSQL database
- **Firebase Authentication**: User identity management
- **Firebase Storage**: Binary file storage
- **Security Rules**: Role-based access control
- **Real-time Listeners**: Live data synchronization

### Data Flow
1. **Authentication**: User signs in via Firebase Auth
2. **Data Access**: Firestore security rules validate user permissions
3. **Real-time Sync**: Changes propagate instantly across devices
4. **Media Handling**: Files stored in Firebase Storage with metadata in Firestore
5. **External APIs**: Weather and location services enhance entry context

## 📱 Installation

### Prerequisites
- Flutter SDK (^3.8.1)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup
- AssemblyAI API key (for transcription features)

### Setup Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/wilson12358/diary-project.git
   cd diary_project
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project
   - Enable Firestore, Authentication, and Storage
   - Download `google-services.json` for Android
   - Configure iOS settings if needed

4. **Environment Variables**
   - Set up AssemblyAI API key
   - Configure weather API credentials
   - Set location service permissions

5. **Build and Run**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Minimum SDK: 21
- Camera and location permissions configured
- Google Services integration

#### iOS
- Camera and location permissions in Info.plist
- Firebase configuration files

## 🚀 Usage

### Getting Started
1. **Sign Up**: Create a new account with email and password
2. **Profile Setup**: Add personal information and preferences
3. **First Entry**: Create your first diary entry with text, images, or voice

### Creating Entries
1. Navigate to the "+" button on the home screen
2. Add title and content
3. Attach media (photos, audio, video)
4. Set emotional rating and tags
5. Save entry

### Managing Entries
- **View**: Browse entries on home screen or calendar
- **Edit**: Modify existing entries anytime
- **Delete**: Remove unwanted entries
- **Search**: Find specific entries using tags or content

### Calendar Navigation
- Use calendar view to browse entries by date
- Quick navigation between months
- Visual indicators for days with entries

### Theme Customization
- Access theme settings in profile
- Choose from multiple color schemes
- Changes apply immediately across the app

## 🗄️ Database Schema

### Collections Structure

#### `entries` Collection
```json
{
  "id": "auto-generated",
  "title": "string",
  "content": "string",
  "date": "timestamp",
  "tags": ["array of strings"],
  "mediaUrls": ["array of file URLs"],
  "emotionalRating": "integer (1-5)",
  "createdAt": "timestamp",
  "userId": "string (auth UID)",
  "location": {
    "latitude": "number",
    "longitude": "number",
    "address": "string"
  },
  "weather": {
    "temperature": "number",
    "description": "string",
    "icon": "string"
  }
}
```

#### `user_profiles` Collection
```json
{
  "userId": "string (auth UID)",
  "displayName": "string",
  "email": "string",
  "gender": "string",
  "dateOfBirth": "timestamp",
  "phoneNumber": "string",
  "preferences": {
    "theme": "string",
    "notifications": "boolean"
  }
}
```

#### `media_files` Collection
```json
{
  "fileId": "auto-generated",
  "userId": "string (auth UID)",
  "fileName": "string",
  "fileType": "string (image/audio/video)",
  "fileUrl": "string",
  "fileSize": "number",
  "uploadedAt": "timestamp",
  "entryId": "string (reference to diary entry)"
}
```

#### `search_history` Collection
```json
{
  "historyId": "auto-generated",
  "userId": "string (auth UID)",
  "searchQuery": "string",
  "searchTimestamp": "timestamp",
  "resultsCount": "number"
}
```

### Security Rules
- **User Isolation**: Users can only access their own data
- **Authentication Required**: All operations require valid user authentication
- **Data Validation**: Input validation and sanitization
- **Permission Checks**: Granular access control per collection

## 🔧 Configuration

### Firebase Rules
The app uses comprehensive Firestore security rules to ensure data privacy and security:
- Read/write permissions based on user authentication
- User-specific data access restrictions
- Secure media file handling

### API Keys
- **AssemblyAI**: For audio transcription
- **Weather API**: For location-based weather information
- **Firebase**: For backend services

### Permissions
- **Camera**: Photo and video capture
- **Microphone**: Audio recording
- **Location**: Automatic location detection
- **Storage**: File access and management

## 🚀 Performance Optimizations

- **Caching**: Intelligent data caching for offline access
- **Pagination**: Efficient data loading with page limits
- **Image Optimization**: Compressed image storage and loading
- **Background Processing**: Non-blocking media operations

## 🔒 Security Features

- **Firebase Security Rules**: Comprehensive access control
- **User Authentication**: Secure login and session management
- **Data Encryption**: Encrypted data transmission
- **Permission Validation**: Client and server-side validation

## 📱 Platform Support

- **Android**: Full feature support with native permissions
- **iOS**: Complete functionality with platform-specific optimizations
- **Web**: Responsive web interface (planned)
- **Desktop**: Cross-platform desktop support (planned)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Check the documentation
- Review existing issues
- Create a new issue with detailed information

## 🔮 Future Enhancements

- **AI-Powered Insights**: Mood analysis and patterns
- **Social Features**: Shared entries and collaboration
- **Advanced Analytics**: Personal growth tracking
- **Export Options**: PDF and backup functionality
- **Multi-language Support**: Internationalization
- **Cloud Sync**: Cross-device synchronization
- **Offline Mode**: Enhanced offline capabilities
