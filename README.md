# Rewarding - Firebase Setup Guide

## 1. Create a Firebase Project (free)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Add project** → name it `rewarding` (or anything)
3. Disable Google Analytics (not needed) → **Create project**

## 2. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## 3. Configure Firebase for your app

From the `rewarding/` project directory:

```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

This will:
- Register Android, iOS, macOS, and web apps
- Auto-generate `lib/firebase_options.dart` with your real config
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS/macOS)
- Create `firebase.json` and `.firebaserc` in the project root

Select **android**, **ios**, **macos**, and **web** when prompted.

## 4. Enable Firestore

1. In Firebase Console → **Build** → **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (fine for family use)
4. Select a region close to you → **Enable**

## 5. Firestore Security Rules

In Firebase Console → Firestore → Rules, replace with:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      // app uses anonymous auth
      allow read, write: if request.auth != null;
    }
  }
}
```

This requires authentication for all reads and writes. The app uses anonymous auth, so users must be signed in to access any data.

## 6. macOS-specific setup

For macOS, you need to enable network access. In `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`, ensure these are present:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

## 7. Run the app

```bash
# iOS Simulator
flutter run -d ios

# macOS
flutter run -d macos

# Android emulator
flutter run -d android
```

## 8. First Launch

On first launch, you'll see a setup wizard to:
- Enter parent name and PIN
- Add your children with names, PINs, and avatar emojis

After setup, everyone can log in with their name + PIN.

## How It Works

- **Parents** can:
  - Award dbux to one or both kids
  - Manually deduct dbux (for cash purchases)
  - Add/edit prizes in the reward shop
  - Approve or deny kids' redemption requests
  - View full transaction history

- **Kids** can:
  - See their dbux balance
  - Browse the prize shop
  - Request to redeem prizes
  - View their transaction history
