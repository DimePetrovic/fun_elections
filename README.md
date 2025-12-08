# Fun Elections - Flutter Frontend

Complete Flutter application for managing elections and tournaments with multiple formats. Currently uses mock data and local state management - ready for backend integration.

## Features

### Election Formats
- **Knockout Tournament**: Single-elimination bracket (2, 4, 8, 16, or 32 competitors)
- **Group Stage**: Round-robin groups with weighted/unweighted scoring
- **League**: Full round-robin tournament (all-vs-all)
- **Legacy Voting**: Traditional voting systems
  - Vote for 1 competitor
  - Vote for multiple competitors
  - Vote for multiple with weighted preferences

### Core Functionality
- ✅ Join public elections (browse all available)
- ✅ Join private elections (using code - hardcoded "AAAA" for testing)
- ✅ Create elections with any format
- ✅ Drag-and-drop competitor reordering (ReorderableListView)
- ✅ Shuffle/randomize competitors
- ✅ Vote in elections
- ✅ Track "My Elections" (Created / Participating / Ended tabs)
- ✅ Share private election codes
- ✅ Admin controls (next match, end election)

## Architecture

### State Management
Uses **Provider** pattern with `ChangeNotifier`:
- `lib/providers/election_store.dart` - Central state management for all elections
- All business logic is in the provider (create, join, vote, navigate matches, etc.)

### Data Models
- `lib/models/election.dart` - Complete data structures:
  - `Election` - Main election entity
  - `Competitor` - Participant with votes/points
  - `Match` - Individual matchup (knockout/league)
  - `Round` - Knockout round container
  - `Group` - Group stage container
  - `ElectionFormat` enum - knockout | group | league | legacy
  - `LegacySubformat` enum - voteForOne | voteForMultiple | voteForMultipleWeighted

### Navigation
- Named routes for all screens
- Dynamic routing for `/election/:id`
- See `lib/main.dart` for route configuration

### Screens
```
lib/screens/
├── home_screen.dart              # Main entry (Join/Create/My Elections)
├── join_screen.dart              # Join type selection (Public/Private)
├── join_public_screen.dart       # Browse all public elections
├── join_private_screen.dart      # Enter private code (use "AAAA")
├── create_screen.dart            # Format selection
├── create_knockout_screen.dart   # Knockout setup with reorderable list
├── create_group_screen.dart      # Group stage configuration
├── create_league_screen.dart     # League setup with reorderable list
├── create_legacy_screen.dart     # Legacy voting configuration
├── election_screen.dart          # Main election view/voting interface
└── my_elections_screen.dart      # Tabbed view of user's elections
```

## Setup & Run

### Prerequisites
- Flutter SDK 3.10.1 or higher
- Dart 3.10.1 or higher

### Installation
```bash
# Navigate to project directory
cd fun_elections

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Or specify device
flutter run -d <device_id>

# List available devices
flutter devices
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/app_test.dart

# Run with verbose output
flutter test --verbose
```

### Code Analysis
```bash
# Check for issues
flutter analyze

# Note: Currently shows 14 deprecation warnings (non-blocking)
# RadioListTile and DropdownButtonFormField API updates needed
```

## Mock Data & Testing

### Hardcoded Values
- **User ID**: `'user123'` (in ElectionStore)
- **Private Code**: `'AAAA'` (to join "Secret Tournament")
- **Mock Elections**: 3 pre-initialized elections in `ElectionStore._initializeMockData()`

### Test Coverage
`test/app_test.dart` includes:
1. Home screen loads correctly
2. Navigation to join/create/my elections
3. Private code join with "AAAA"
4. Create knockout flow
5. ElectionStore logic (create, join, randomize)
6. Randomize functionality

All tests passing ✅ (6/6)

## Backend Integration TODOs

Currently, the app uses **in-memory state** with mock data. To integrate with your .NET backend:

### 1. API Service Layer
Create `lib/services/api_service.dart`:
```dart
class ApiService {
  final String baseUrl = 'https://your-backend.com/api';
  
  // TODO: Implement HTTP calls
  Future<List<Election>> fetchPublicElections() async { }
  Future<Election> joinPrivateElection(String code) async { }
  Future<Election> createElection(Election election) async { }
  Future<void> vote(String electionId, String competitorId) async { }
  // ... etc
}
```

### 2. Authentication
Replace `currentUserId = 'user123'` in `election_store.dart`:
- Add JWT token storage (use `flutter_secure_storage`)
- Implement login/register screens
- Connect to `/api/auth/login` and `/api/auth/register` endpoints
- Store token and include in API headers

### 3. Update ElectionStore
In `lib/providers/election_store.dart`:
```dart
// Replace:
final List<Election> _elections = [];
_initializeMockData();

// With:
final ApiService _apiService = ApiService();

Future<void> loadElections() async {
  _elections = await _apiService.fetchPublicElections();
  notifyListeners();
}

// Update all methods to use _apiService instead of local manipulation
```

### 4. Real-time Updates
For live voting/match updates:
- Add WebSocket connection (use `web_socket_channel` package)
- Subscribe to election channels
- Update UI on incoming messages
- Connect to SignalR hub on backend

### 5. Key Files to Modify
```
lib/providers/election_store.dart  # Replace mock methods with API calls
lib/models/election.dart           # Add fromJson/toJson serialization
lib/services/api_service.dart      # CREATE - HTTP client with error handling
lib/services/auth_service.dart     # CREATE - JWT authentication
lib/services/websocket_service.dart # CREATE - Real-time updates
```

### 6. Backend Endpoints Needed
```
GET    /api/elections/public          # List public elections
POST   /api/elections/join/code       # Join with private code
POST   /api/elections                 # Create new election
GET    /api/elections/:id             # Get election details
POST   /api/elections/:id/vote        # Submit vote
POST   /api/elections/:id/next-match  # Admin: advance match
POST   /api/elections/:id/end         # Admin: end election
GET    /api/elections/my/created      # User's created elections
GET    /api/elections/my/participating # User's joined elections
```

### 7. Data Persistence
Remove `_initializeMockData()` and replace with:
```dart
Future<void> initialize() async {
  await loadElections();
  await loadMyElections();
}
```

Call in `main.dart` before `runApp()` or show splash screen.

## Project Structure

```
lib/
├── main.dart                  # App entry point, routing setup
├── models/
│   └── election.dart          # Data models (Election, Competitor, Match, etc.)
├── providers/
│   └── election_store.dart    # State management (ChangeNotifier)
├── screens/                   # All UI screens (11 total)
└── services/                  # TODO: Create for API integration

test/
└── app_test.dart              # Widget tests (6 tests, all passing)

Backend.Api/                   # .NET backend (separate project)
Backend.BL/                    # Business logic layer
Backend.DAL/                   # Data access layer
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5        # State management
  uuid: ^4.5.2            # ID generation
  cupertino_icons: ^1.0.8 # iOS icons
```

## Known Issues

1. **Deprecated APIs** (14 warnings, non-blocking):
   - `RadioListTile.groupValue/onChanged` → Migrate to `RadioGroup`
   - `DropdownButtonFormField.value` → Use `initialValue`
   
2. **In-Memory State**: App resets on restart (no persistence until backend integration)

3. **Mock Authentication**: No real login flow yet

## Development Notes

### Adding New Election Format
1. Add enum value to `ElectionFormat` in `election.dart`
2. Create screen `lib/screens/create_<format>_screen.dart`
3. Add route in `main.dart`
4. Implement generation logic in `election_store.dart`
5. Add format-specific view in `election_screen.dart`

### Testing Strategy
- Widget tests for navigation flows
- Unit tests for ElectionStore business logic
- Integration tests for complete user journeys (TODO)

### Code Style
- Follow official Flutter style guide
- Use `flutter format .` before committing
- Max line length: 80 characters (enforced by formatter)

## License

[Your License Here]

## Contributors

[Your Name/Team]

---

**Status**: ✅ All core features implemented, tests passing, ready for backend integration
