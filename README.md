# FamilyVault Client

Flutter client for the FamilyVault local media server — browse, upload, view, and share photos/videos.

## Tech Stack

- Flutter 3.x, Dart 3.9+
- Provider (state management), Material 3 dark theme
- `http` for API calls, `flutter_secure_storage` for tokens
- `video_player` for streaming, `photo_view` for pinch-to-zoom, `file_picker` for uploads

## Getting Started

### Install & Run

```bash
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                  # App entry, MultiProvider setup
├── app_theme.dart             # Material 3 dark theme, AppColors, AppSpacing, AppRadius
├── config/
│   └── api_config.dart        # API endpoint constants
├── models/
│   ├── auth_response.dart     # JWT + refresh token model
│   ├── file_item.dart         # File/album model (album, image, video types)
│   └── share.dart             # Share model with permission helpers
├── services/
│   ├── api_service.dart       # HTTP client with auth headers, 401 auto-refresh
│   ├── token_storage.dart     # Secure storage for tokens + server address
│   └── media_service.dart     # All file/share API calls
├── providers/
│   ├── auth_provider.dart     # Auth state, login/logout
│   ├── file_provider.dart     # Folder contents, CRUD operations
│   ├── share_provider.dart    # Share state management
│   └── upload_provider.dart   # Upload task tracking with per-file progress
├── screens/
│   ├── login_screen.dart           # Login with server address field
│   ├── main_screen.dart            # Bottom nav: My Files / Shared / My Shares
│   ├── my_files_screen.dart        # Root file browser
│   ├── album_detail_screen.dart    # Nested album browsing, breadcrumbs
│   ├── image_viewer_screen.dart    # Pinch-to-zoom image gallery
│   ├── video_player_screen.dart    # Video playback with controls
│   ├── shared_with_me_screen.dart  # Albums shared with you
│   ├── shared_album_detail_screen.dart
│   └── my_shares_screen.dart       # Shares you created, revoke access
└── widgets/
    ├── album_card.dart
    ├── media_card.dart
    ├── loading_grid.dart
    ├── empty_state.dart
    ├── user_avatar.dart
    ├── permission_badge.dart
    ├── breadcrumb_trail.dart
    ├── confirm_dialog.dart
    ├── create_album_dialog.dart
    ├── share_album_dialog.dart
    └── upload_bottom_sheet.dart
```

## Features

- **Authentication** — JWT login with auto-refresh, server address configurable per-device
- **My Files** — browse albums and media in a grid, nested albums with breadcrumbs
- **Upload** — multi-file upload with progress tracking via `file_picker`
- **Image Viewer** — swipeable gallery with pinch-to-zoom (`photo_view`)
- **Video Player** — HTTP streaming with Range support, play/pause, seek, progress bar
- **Sharing** — share albums with registered users (VIEW or EDIT permission)
- **Shared With Me** — browse albums others shared with you
- **My Shares** — manage and revoke shares you created

## Theme

OLED-optimized dark Material 3 theme:

- Background: `#0A0A0F`
- Primary: `#6366F1` (indigo)
- Surface: `#12121A`
- Full design tokens in `app_theme.dart` (AppColors, AppSpacing, AppRadius)
