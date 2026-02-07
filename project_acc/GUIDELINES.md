# Project Guidelines: Product Scanner & Inventory Manager

## General Guidelines

### Code Quality
* Always handle both String and number types when reading from Firestore (price, quantity fields)
* Use safe type conversion with `tryParse()` to prevent TypeErrors
* Include null-safety checks for all optional fields
* Keep files under 500 lines - split into smaller components when needed
* Use meaningful variable names that describe the data they hold
* Add comments for complex business logic (like stat calculations)

### File Organization
* Place reusable widgets in separate files under `lib/widgets/`
* Keep models in `lib/models/`
* Keep pages in `lib/pages/`
* Keep forms/modals in `lib/forms/`
* One widget class per file (except small private helper widgets)

### Navigation
* Always use named routes defined in `main.dart`
* Use `pushReplacementNamed()` for bottom navigation to prevent stack buildup
* Use `pushNamedAndRemoveUntil('/', (route) => false)` for logout
* Set `currentIndex` on BottomNavigationBar to highlight active page

### State Management
* Use `setState()` for simple local state
* Use `SharedPreferences` for user settings persistence
* Use Firestore `StreamBuilder` for real-time data
* Check `mounted` before calling `setState()` in async functions

### Error Handling
* Always use try-catch for Firestore operations
* Show user-friendly error messages via `SnackBar`
* Provide fallback values for missing data
* Log errors to console for debugging

---

## Design System

### Color Palette

**Primary Colors:**
```dart
Colors.deepPurple.shade700  // #6B46C1 - Primary actions, headers
Colors.blue.shade500        // #3B82F6 - Accents, gradients
```

**Semantic Colors:**
```dart
Colors.green               // Success, positive values
Colors.orange              // Warnings, low stock alerts
Colors.red                 // Errors, delete actions
Colors.grey.shade50        // Card backgrounds
Colors.grey.shade600       // Secondary text
```

**Gradients:**
```dart
// Auth page background
LinearGradient(
  colors: [Colors.deepPurple.shade700, Colors.blue.shade500],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Stat cards
LinearGradient(
  colors: [color.withOpacity(0.8), color],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

### Typography

**Sizes:**
* Page titles: 28px, bold
* Section headers: 20px, bold
* Card titles: 16px, bold
* Body text: 14px, regular
* Labels: 12px, regular/bold

**Font Family:**
* Default Material Design fonts (Roboto)
* Consider Google Fonts (Inter/Poppins) for premium feel

### Spacing

**Standard Units:**
* Extra small: 4px
* Small: 8px
* Medium: 12px
* Large: 16px
* Extra large: 24px

**Usage:**
* Card padding: 12px
* Page padding: 16px
* Section spacing: 24px
* Form field spacing: 16px

### Border Radius

**Consistency:**
* Cards: 8px
* Buttons: 12px
* Modal dialogs: 20px
* Chips/Badges: 4px

---

## Component Guidelines

### Stat Cards

**Purpose:** Display key metrics on dashboard

**Structure:**
```dart
Container with:
  - Gradient background (color-specific)
  - Box shadow for depth
  - Icon at top
  - Large value text
  - Small label text
```

**Colors:**
* Total Products: Blue
* Total Value: Green
* Low Stock Alerts: Orange
* Categories: Purple

**Usage:**
* Always use in 2x2 grid on dashboard
* Values should be calculated from real data
* Update in real-time via StreamBuilder

---

### Bottom Navigation Bar

**Structure:**
* Exactly 3 items: Dashboard, Products, Settings
* Icons: `Icons.dashboard`, `Icons.inventory_2`, `Icons.settings`
* Labels: Always show
* Current index: Must be set on each page

**Behavior:**
* Use `pushReplacementNamed()` on tap
* Don't navigate if already on that page (check index)
* Consistent across all main pages

**Implementation:**
```dart
BottomNavigationBar(
  currentIndex: 0, // Set to current page
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Products'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ],
  onTap: (index) {
    if (index == 0) Navigator.of(context).pushReplacementNamed('/dashboard');
    if (index == 1) Navigator.of(context).pushReplacementNamed('/products');
    if (index == 2) Navigator.of(context).pushReplacementNamed('/settings');
  },
)
```

---

### Buttons

**Primary Button (FilledButton/ElevatedButton):**
* Purpose: Main actions (Sign In, Save, Add)
* Color: `Colors.deepPurple.shade700`
* Text color: White
* Border radius: 12px
* Padding: 12px vertical
* Full width for forms

**Secondary Button (OutlinedButton):**
* Purpose: Alternative actions (Cancel, Edit)
* Border color: Primary or action color
* Text color: Matches border
* Border radius: 12px
* Padding: 12px horizontal, 6px vertical

**Danger Button:**
* Use red color for destructive actions
* Always show confirmation dialog before action
* Example: Delete product

**States:**
* Disabled: Set `onPressed: null`
* Loading: Show `CircularProgressIndicator` instead of text

---

### Form Fields

**Standard TextField:**
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Field Name',
    hintText: 'Placeholder text',
    prefixIcon: Icon(...),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  ),
)
```

**Validation:**
* Always validate required fields
* Show error messages below field
* Use `validator` in Form widgets
* Check for empty, null, and invalid formats

**Password Fields:**
* Always include visibility toggle
* Use `obscureText: true` by default
* Toggle icon: `Icons.visibility` / `Icons.visibility_off`

---

### Cards

**Product Cards:**
* Border: 1px solid grey.shade300
* Border radius: 8px
* Padding: 12px
* Margin bottom: 12px
* Include: Name, price, category, quantity, actions

**Low Stock Alert Cards:**
* Background: `Colors.orange.shade50`
* Border: `Colors.orange.shade300`
* Icon: `Icons.warning_amber` in orange.shade700
* Show quantity badge

**Empty States:**
* Center content vertically and horizontally
* Large icon (48-64px) in grey
* Helpful message text
* Suggestion for next action

---

## Firebase Guidelines

### Firestore Structure

**Products Collection:**
```
products/ (collection)
  {productId}/ (document)
    - userId: string (user who created it)
    - name: string (required)
    - price: number (store as number, not string!)
    - quantity: number (store as number, not string!)
    - category: string (required)
    - barcode: string (optional)
    - createdAt: timestamp (auto-generated)
```

**Credentials Collection (Temporary):**
```
collection_credential/ (collection)
  {docId}/ (document)
    - name: string
    - username: string
    - password: string (INSECURE - migrate to Firebase Auth!)
```

### Data Types

**IMPORTANT:** Always store numeric data as numbers, not strings!

**When Writing:**
```dart
await firestore.collection('products').add({
  'name': nameController.text,
  'price': double.parse(priceController.text), // ✅ Number
  'quantity': int.parse(quantityController.text), // ✅ Number
  'category': selectedCategory,
});
```

**When Reading:**
```dart
// Safe conversion handles both String and num
double price = 0;
if (data['price'] is String) {
  price = double.tryParse(data['price'] as String) ?? 0;
} else if (data['price'] is num) {
  price = (data['price'] as num).toDouble();
}
```

### Real-time Updates

**Use StreamBuilder:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: firestore.collection('products').snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return EmptyStateWidget();
    }
    // Build UI with data
  },
)
```

---

## Settings & Preferences

### SharedPreferences Keys

**Standardized Keys:**
* `isLoggedIn` - boolean
* `username` - string  
* `userEmail` - string
* `soundEnabled` - boolean
* `vibrationEnabled` - boolean
* `theme` - string ('light', 'dark', 'system')
* `lowStockThreshold` - int

**Usage:**
* Load settings in `initState()`
* Save immediately after user changes
* Provide default values if key doesn't exist

---

## Web Compatibility

### Platform Checks

**When to Check:**
* Before using mobile-only packages (scanner, vibration)
* For platform-specific UI adjustments

**How to Check:**
```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

### Known Web Limitations

**Don't Work on Web:**
* `mobile_scanner` - Use manual input or html5-qrcode alternative
* `vibration` - Disable feature or hide toggle
* `image_picker` (file_picker works better)

**Solutions:**
* Provide fallback UI for web users
* Show helpful messages ("Feature unavailable on web")
* Consider web-compatible alternatives

---

## Performance Best Practices

### Firestore Queries

* Use `.where()` filters to reduce data transfer
* Limit results with `.limit()`
* Index fields used in queries
* Use pagination for large lists

### Widget Rebuilds

* Use `const` constructors where possible
* Don't create widgets in build methods
* Extract widgets to separate classes
* Use `ValueListenableBuilder` for targeted updates

### Images & Assets

* Optimize image sizes before upload
* Use `CachedNetworkImage` for remote images
* Lazy load images in lists

---

## Security Best Practices

### Authentication

**Current Issue:**
⚠️ Passwords stored in plain text in Firestore (INSECURE!)

**Recommended Migration:**
```dart
// Use Firebase Authentication instead
import 'package:firebase_auth/firebase_auth.dart';

// Sign Up
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Sign In
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Check auth state
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  // Update UI based on auth state
});
```

### Firestore Security Rules

**Recommended Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Products: Only authenticated users can CRUD
    match /products/{productId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Testing Guidelines

### Manual Testing Checklist

**Authentication:**
- [ ] Sign up creates new user
- [ ] Sign in with valid credentials
- [ ] Sign in fails with invalid credentials
- [ ] Session persists on refresh
- [ ] Logout clears session

**Dashboard:**
- [ ] Stat cards show correct calculations
- [ ] Low stock alerts display when quantity ≤ threshold
- [ ] Category breakdown accurate
- [ ] Real-time updates when products change

**Products:**
- [ ] All products display
- [ ] Search filters by name and barcode
- [ ] Category filter works
- [ ] Add product saves to Firestore
- [ ] Edit product updates correctly
- [ ] Delete shows confirmation and removes product
- [ ] Low stock badge appears correctly

**Settings:**
- [ ] All toggles save to SharedPreferences
- [ ] Theme switch works (if implemented)
- [ ] Threshold updates affect dashboard
- [ ] Settings persist after app restart

### Browser Testing

**Chrome (Primary):**
* Test all features
* Check responsive design (resize window)
* Verify no console errors
* Test with DevTools open

**Other Browsers (Optional):**
* Edge, Firefox, Safari
* Verify basic functionality

---

## Future Enhancements

### Short Term
* Add web-compatible barcode scanner (html5-qrcode)
* Implement proper Firebase Authentication
* Add product images with upload
* Export data to CSV/Excel
* Print labels with barcodes

### Long Term  
* Multi-user support with permissions
* Product history/audit log
* Analytics and reports
* Barcode generation
* Mobile apps (Android/iOS)
* Offline mode with sync

---

## Code Examples

### Creating a New Page

```dart
import 'package:flutter/material.dart';

class NewPage extends StatefulWidget {
  const NewPage({super.key});

  @override
  State<NewPage> createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page Title'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Your content here
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Update this
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) Navigator.of(context).pushReplacementNamed('/dashboard');
          if (index == 1) Navigator.of(context).pushReplacementNamed('/products');
          if (index == 2) Navigator.of(context).pushReplacementNamed('/settings');
        },
      ),
    );
  }
}
```

### Adding a New Route

**In `main.dart`:**
```dart
routes: {
  '/': (context) => const AuthPage(),
  '/dashboard': (context) => const DashboardPage(),
  '/products': (context) => const ProductsPage(),
  '/settings': (context) => const SettingsPage(),
  '/new-page': (context) => const NewPage(), // Add here
}
```

---

## Project Maintenance

### Regular Tasks
* Review and fix linter warnings
* Update dependencies monthly (`flutter pub upgrade`)
* Check for deprecated APIs
* Remove unused imports and files
* Run `flutter clean` if build issues occur

### Version Control
* Commit working features incrementally
* Use descriptive commit messages
* Don't commit sensitive data (API keys)
* Keep `.gitignore` updated

---

**Last Updated:** January 21, 2026  
**Version:** 1.0
