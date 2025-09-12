# Cherry Music LT

A music player application built with Flutter.

## Storage Access Permissions

This application requires access to media files for downloading music tracks for offline playback. The app complies with Google Play Store policies by using the proper permission model:

- For Android 13+: Uses READ_MEDIA_AUDIO and READ_MEDIA_IMAGES permissions
- For Android 10-12: Uses scoped storage model with MediaStore APIs
- For Android 9 and below: Uses legacy storage permissions

The app does NOT use the MANAGE_EXTERNAL_STORAGE permission (All Files Access) as it only needs to access media files through the MediaStore API.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
