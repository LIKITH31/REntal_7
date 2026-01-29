<<<<<<< HEAD
# 🏠 Rental App - Rent & Resale Marketplace

A modern Flutter-based rental and resale marketplace application with Firebase backend, real-time location-based item discovery, and beautiful 3D UI animations.

## ✨ Features

### 🔐 Authentication
- **Email/Password Authentication** - Secure sign up and sign in
- **User Profiles** - Automatic profile creation in Firestore
- **Session Management** - Persistent login state

### 📍 Location-Based Discovery
- **GPS Integration** - Automatic current location detection
- **Distance Calculation** - Haversine formula for accurate distances
- **Adjustable Search Radius** - 1-50 km range
- **Nearby Items** - Items sorted by proximity
- **Real-time Distance Display** - See how far items are from you

### 🎨 Beautiful UI
- **Material 3 Design** - Modern, clean interface
- **3D Animations** - Interactive card carousel with perspective transforms
- **Smooth Transitions** - Flutter Animate for fluid animations
- **Dark/Light Themes** - Automatic theme switching
- **Responsive Layout** - Works on all screen sizes

### 📦 Item Management
- **Add Listings** - Create rental/sale items with details
- **Real-time Sync** - Firestore integration for instant updates
- **Category System** - Electronics, Vehicles, Sports, Tools, etc.
- **Flexible Pricing** - Daily, weekly, monthly rental rates
- **Security Deposits** - Optional deposit amounts
- **Location Tagging** - Items tagged with GPS coordinates

### 🗺️ Interactive Map
- **Google Maps Integration** - View items on map
- **Custom Markers** - Category-based marker icons
- **Search UI** - Find items by location
- **Bottom Sheet** - Quick item preview

### 👤 User Features
- **Profile Screen** - View user stats and info
- **My Rentals** - Track active, pending, completed rentals
- **Sign Out** - Secure logout with confirmation

## 🛠️ Tech Stack

- **Framework**: Flutter 3.9.2+
- **State Management**: Riverpod 3.0.3
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
- **Maps**: Google Maps Flutter 2.14.0
- **Location**: Geolocator 14.0.2
- **Animations**: Flutter Animate 4.5.2
- **UI**: Material 3

## 📱 Screenshots

### Home Screen
- 3D carousel with nearby items
- Distance badges on each card
- Category grid
- Search radius indicator

### Add Listing
- Image upload placeholder
- Form validation
- Category selection
- Flexible pricing options
- Location auto-detection

### Profile
- User stats (Items Listed, Rentals, Rating)
- Menu options
- Sign out functionality

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Android Studio / VS Code
- Firebase Account
- Google Maps API Key

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/LIKITH31/Rental-app.git
cd Rental-app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Create Firestore Database
   - Download `google-services.json` and place in `android/app/`
   - Update `lib/firebase_options.dart` with your config

4. **Google Maps Setup**
   - Get API key from [Google Cloud Console](https://console.cloud.google.com)
   - Enable Maps SDK for Android
   - Add key to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```

5. **Run the app**
```bash
flutter run
```

## 📂 Project Structure

```
lib/
├── core/
│   ├── models/
│   │   └── item_model.dart          # Item data model
│   ├── providers/
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── items_provider.dart      # Items & Firestore
│   │   └── location_provider.dart   # Location state
│   ├── services/
│   │   ├── firestore_service.dart   # Firestore operations
│   │   └── location_service.dart    # GPS & distance calc
│   └── theme/
│       └── app_theme.dart           # Material 3 themes
├── features/
│   ├── auth/
│   │   └── presentation/screens/auth_screen.dart
│   ├── home/
│   │   └── presentation/screens/home_screen.dart
│   ├── map/
│   │   └── presentation/screens/map_screen.dart
│   ├── add_listing/
│   │   └── presentation/screens/add_listing_screen.dart
│   ├── rentals/
│   │   └── presentation/screens/rentals_screen.dart
│   └── profile/
│       └── presentation/screens/profile_screen.dart
└── main.dart
```

## 🔧 Configuration

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /items/{itemId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.ownerId;
    }
  }
}
```

## 📖 Usage

### Sign Up / Sign In
1. Open the app
2. Navigate to Profile tab
3. Tap "Sign In"
4. Enter email, password, and name (for sign up)
5. Tap "Sign Up" or "Sign In"

### Add an Item
1. Ensure you're logged in
2. Go to "Add" tab
3. Fill in item details:
   - Title
   - Category
   - Description
   - Price (rental or sale)
   - Security deposit (optional)
4. Tap "Create Listing"
5. Item appears for all users instantly!

### View Nearby Items
1. Allow location permission when prompted
2. Home screen shows items within search radius
3. Tap radius chip to adjust (1-50 km)
4. Swipe through 3D carousel
5. Each card shows distance from you

## 🎯 Key Features Explained

### Location-Based Discovery
The app uses the Haversine formula to calculate accurate distances between the user's location and item locations. Items are filtered by the search radius and sorted by proximity.

### Real-time Sync
All items are stored in Firestore and synced in real-time. When a user adds an item, it immediately appears for all other users within range.

### 3D UI
The home screen features a 3D card carousel with perspective transforms, creating an engaging and modern user experience.

## 🔐 Security

- Firebase Authentication for secure user management
- Firestore security rules to protect user data
- Owner-only edit/delete permissions for items
- Location permissions handled gracefully

## 🐛 Known Issues

- Google Sign-In temporarily disabled (API compatibility)
- Image upload not yet implemented (placeholder UI ready)
- Reverse geocoding for addresses not implemented

## 🚧 Roadmap

- [ ] Image upload with Firebase Storage
- [ ] Google Sign-In integration
- [ ] Reverse geocoding for addresses
- [ ] Push notifications
- [ ] In-app messaging
- [ ] Payment integration
- [ ] Rating & review system
- [ ] Booking calendar
- [ ] Admin dashboard

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Developer

**Likith**
- GitHub: [@LIKITH31](https://github.com/LIKITH31)
- Email: likithpara31@gmail.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Maps for location services
- Material Design for UI guidelines

---

**⭐ Star this repo if you find it helpful!**
=======
# rental_
13-01
>>>>>>> a7a3fde13c578f02be48dd5771bf71dc0879e773
