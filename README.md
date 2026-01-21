# Referral System App - Documentation

## Project Overview

A Flutter mobile application that implements a complete referral system where users can sign up, share referral codes, and earn reward points when others join using their code.

---

## Table of Contents

1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Setup Instructions](#setup-instructions)
5. [Firebase Configuration](#firebase-configuration)
6. [How It Works](#how-it-works)
7. [Screens Description](#screens-description)
8. [Database Schema](#database-schema)
9. [Future Enhancements](#future-enhancements)

---

## Features

✅ **User Authentication**
- Email and password-based signup/login
- Secure authentication using Firebase Auth

✅ **Referral System**
- Unique referral code generation for each user
- Apply referral code during signup
- Track referred users
- Earn 10 reward points per successful referral

✅ **Dashboard**
- View reward points
- View total referrals count
- Share referral code via multiple platforms
- Copy referral code to clipboard

✅ **Profile Management**
- View complete profile information
- See all referred users with details
- Track join dates of referred users

---

## Tech Stack

**Frontend:**
- Flutter (Dart)
- Material Design UI

**Backend:**
- Firebase Authentication
- Firebase Realtime Database

**Packages Used:**
- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication
- `firebase_database` - Realtime database operations
- `share_plus` - Sharing functionality

---

## Project Structure

```
lib/
├── main.dart              # App entry point and routing
├── screens/
│   ├── login.dart         # Login screen
│   ├── signup.dart        # Signup screen with referral
│   ├── dashboard.dart     # Main dashboard
│   └── profile.dart       # User profile and referrals list
```

---

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0 or higher)
- Firebase account
- Android Studio / VS Code
- Git

### Installation Steps

1. **Clone the Repository**
```bash
git clone <your-repo-url>
cd referral-system
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Firebase Setup**
- Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
- Add Android/iOS app to your Firebase project
- Download `google-services.json` (Android) and place in `android/app/`
- Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`

4. **Enable Firebase Services**
- Enable Email/Password authentication in Firebase Console
- Create Realtime Database in Firebase Console

5. **Update Firebase Rules** (See [Firebase Configuration](#firebase-configuration))

6. **Run the App**
```bash
flutter run
```

---

## Firebase Configuration

### Authentication Setup

1. Go to Firebase Console → Authentication
2. Enable **Email/Password** sign-in method

### Realtime Database Rules

```json
{
  "rules": {
    "users": {
      ".read": "auth != null",
      ".indexOn": ["referralCode"],
      "$uid": {
        ".write": "auth != null"
      }
    }
  }
}
```

**Rule Explanation:**
- `.read: "auth != null"` - All authenticated users can read data (required for referral code lookup)
- `.indexOn: ["referralCode"]` - Index on referralCode for efficient queries
- `.write: "auth != null"` - Any authenticated user can write (needed for updating referrer's data)

---

## How It Works

### 1. User Signup Flow

```
User fills signup form
    ↓
Firebase Auth creates user account
    ↓
Generate unique referral code (REF + first 6 chars of UID)
    ↓
Save user data to Realtime Database
    ↓
If referral code entered:
    → Find referrer's UID
    → Add 10 points to referrer
    → Increment referrer's count
    → Add new user to referrer's list
    ↓
Navigate to Login
```

### 2. Referral Code Generation

```dart
String generateReferralCode(String uid) {
  return "REF${uid.substring(0, 6)}";
}
```
Example: User UID = `7gqJFhh9eVXN...` → Referral Code = `REF7gqJFh`

### 3. Points System

- **10 points** awarded per successful referral
- Points are added immediately when someone signs up with your code
- Points are tracked in the `rewardPoints` field

---

## Screens Description

### 1. Login Screen (`login.dart`)
- Email and password input fields
- Login button with loading state
- Link to signup screen
- Error handling for invalid credentials

### 2. Signup Screen (`signup.dart`)
- Full name, email, password input
- Optional referral code field
- Validates all required fields
- Creates user account
- Applies referral bonus if code is valid
- Shows success/error messages

### 3. Dashboard Screen (`dashboard.dart`)
- Welcome message with user name
- Stats cards showing:
  - Total reward points
  - Number of referrals
- Referral code display
- Copy to clipboard functionality
- Share button (WhatsApp, SMS, etc.)
- Navigation to profile
- Logout functionality

### 4. Profile Screen (`profile.dart`)
- User profile card with avatar
- Stats overview (points, referrals, code)
- Complete list of referred users showing:
  - Name
  - Email
  - Join date
  - Points earned (+10)
- Empty state when no referrals
- Pull to refresh

---

## Database Schema

### Users Collection Structure

```json
{
  "users": {
    "<user_uid>": {
      "name": "John Doe",
      "email": "john@example.com",
      "referralCode": "REF7gqJFh",
      "rewardPoints": 20,
      "peopleReferred": 2,
      "referredUsers": {
        "<referred_user_uid_1>": {
          "name": "Jane Smith",
          "email": "jane@example.com",
          "joinedAt": "2025-01-21T10:30:00.000Z"
        },
        "<referred_user_uid_2>": {
          "name": "Bob Wilson",
          "email": "bob@example.com",
          "joinedAt": "2025-01-21T11:45:00.000Z"
        }
      }
    }
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `name` | String | User's full name |
| `email` | String | User's email address |
| `referralCode` | String | Unique 9-character referral code |
| `rewardPoints` | Integer | Total points earned from referrals |
| `peopleReferred` | Integer | Count of successful referrals |
| `referredUsers` | Map | Object containing all referred users' details |

---

## Key Functions

### 1. Generate Referral Code
```dart
String generateReferralCode(String uid) {
  return "REF${uid.substring(0, 6)}";
}
```

### 2. Find Referrer by Code
```dart
Future<String?> getReferrerUid(String code) async {
  final snap = await db.orderByChild("referralCode").equalTo(code).get();
  if (snap.exists && snap.value != null) {
    final data = snap.value as Map;
    return data.keys.first.toString();
  }
  return null;
}
```

### 3. Update Referrer Rewards
```dart
await db.child(refUid).update({
  "rewardPoints": currentReward + 10,
  "peopleReferred": currentPeople + 1,
  "referredUsers": updatedReferredList,
});
```

---

## Security Considerations

1. **Firebase Rules**: Properly configured to allow authenticated access only
2. **Password Security**: Minimum 6 characters enforced by Firebase Auth
3. **Data Validation**: All inputs validated before processing
4. **Self-referral Prevention**: Users cannot use their own referral code

---

## Testing

### Test Scenarios

1. **Signup without referral code**
   - Should create account successfully
   - Should generate unique referral code

2. **Signup with valid referral code**
   - Should create account
   - Should add 10 points to referrer
   - Should appear in referrer's list

3. **Signup with invalid referral code**
   - Should create account anyway
   - Should show "Invalid referral code" message

4. **Dashboard functionality**
   - Should display correct stats
   - Should copy code to clipboard
   - Should share code via platforms

5. **Profile screen**
   - Should show all referred users
   - Should display correct points and counts

---

## Common Issues & Solutions

### Issue 1: Permission Denied Error
**Solution**: Update Firebase Realtime Database rules as specified in [Firebase Configuration](#firebase-configuration)

### Issue 2: Index Not Defined Error
**Solution**: Add `.indexOn: ["referralCode"]` to database rules

### Issue 3: Referral Code Not Found
**Solution**: Ensure the referral code is copied correctly (case-sensitive)

---

## Future Enhancements

🔮 **Planned Features:**

1. **Tiered Rewards System**
   - Different point values for different levels
   - Bonus for reaching milestones (10 referrals, 50 referrals, etc.)

2. **Points Redemption**
   - Convert points to rewards
   - Coupon codes or discounts

3. **Leaderboard**
   - Show top referrers
   - Monthly/yearly rankings

4. **Social Login**
   - Google Sign-In
   - Facebook Login

5. **Notifications**
   - Push notifications for successful referrals
   - Milestone achievements

6. **Analytics Dashboard**
   - Referral trends over time
   - Conversion rates
   - User growth charts

7. **Referral Link**
   - Generate deep links
   - Track clicks on referral links

8. **Admin Panel**
   - Manage users
   - View system-wide statistics
   - Adjust point values

---

## API Reference

### Firebase Authentication

```dart
// Sign up
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Login
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Logout
await FirebaseAuth.instance.signOut();
```

### Firebase Realtime Database

```dart
// Read data
final snapshot = await db.child(uid).get();

// Write data
await db.child(uid).set(data);

// Update data
await db.child(uid).update(data);

// Query with index
final snapshot = await db.orderByChild("referralCode").equalTo(code).get();
```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## License

This project is open source and available under the MIT License.

---

## Contact & Support

For questions or support, please contact:
- Email: your.email@example.com
- GitHub Issues: [Create an issue](your-repo-url/issues)

---

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI components

---

## Version History

**v1.0.0** (January 2026)
- Initial release
- Basic referral system
- User authentication
- Dashboard and profile screens
- Points tracking

---

**Last Updated:** January 21, 2026