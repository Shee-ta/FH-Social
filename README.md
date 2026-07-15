# FH_Social

<<<<<<< HEAD
A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:
=======
A Flutter frontend with a Spring Boot backend.

## Local Network Setup (Mac backend + phone app)

Run the backend on your Mac and connect Android/iOS devices on the same Wi-Fi.

1. Find your Mac LAN IP (for example, 192.168.1.42).
2. Start backend from project root:

```sh
docker compose up --build
```

3. Start frontend on a physical device with BACKEND_URL:

```sh
cd frontend
flutter run -d <device-id> --dart-define=BACKEND_URL=http://192.168.1.42:3000
```

Notes:
- Physical devices cannot use localhost for the Mac backend.
- Android emulator can use http://10.0.2.2:3000.
- Web keeps using localhost unless BACKEND_URL is provided.

## Export / Build

Android (APK):

```sh
cd frontend
flutter build apk --release --dart-define=BACKEND_URL=http://192.168.1.42:3000
```

iOS (from macOS with Xcode + CocoaPods installed):

```sh
cd frontend
flutter build ios --release --dart-define=BACKEND_URL=http://192.168.1.42:3000
```

## Required Tooling

Your machine must have:
- Android SDK (Android Studio setup)
- Xcode full installation
- CocoaPods

Check with:

```sh
flutter doctor -v
```

## Helpful Flutter Docs
>>>>>>> 9fecced (Added introduction to export app to mobile)

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

<<<<<<< HEAD
For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
>>>>>>> 9fecced (Added introduction to export app to mobile)
