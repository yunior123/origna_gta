# App Force-Update Mechanism

The origna_gta Flutter app implements a force-update mechanism that prompts users on mobile/tablet devices to update when a new version is required.

## Implementation

### 1. Dependency

Added `package_info_plus: ^8.0.0` to `pubspec.yaml` to fetch the current app version.

### 2. Service: AppUpdateService

**File**: `lib/services/app_update_service.dart`

The `AppUpdateService` class provides:

- `checkForUpdate()`: Fetches the minimum required version from OrignaBase and compares it against the current app version
- `_isVersionLower()`: Helper method that compares semantic versions (e.g., "1.1.0" vs "1.2.0")

**Flow**:
1. Fetches current version from `PackageInfo.fromPlatform()`
2. Calls `GET /config/min_app_version` on OrignaBase
3. Parses response: expects JSON with `{"value": "X.Y.Z"}` structure
4. Compares versions using semantic versioning rules
5. Returns the minimum version string if update is required, or null otherwise
6. Logs warnings and gracefully handles network errors (non-blocking)

### 3. Widget: UpdateRequiredDialog

**File**: `lib/widgets/update_required_dialog.dart`

Non-dismissible `AlertDialog` that:
- Shows `app.update_required_title` (translated)
- Shows `app.update_required_message` with the minimum version inserted via `{}`
- Opens the app store (iOS App Store or Google Play) when user taps "Update Now"
- Cannot be dismissed by tapping outside or using back button (`PopScope(canPop: false)`)

**Store URLs** (TODO — replace with actual app IDs when published):
- iOS: `https://apps.apple.com/app/orignagta/id000000000`
- Android: `https://play.google.com/store/apps/details?id=ca.orignagta.app`

### 4. Integration: OrignaApp

**File**: `lib/origna_app.dart`

The version check is added in `_OrignaAppState.initState()`:
- Mobile/tablet only (skips web)
- Runs on first frame via `WidgetsBinding.instance.addPostFrameCallback()`
- Only shows dialog if update is required AND widget is still mounted
- Non-blocking: network errors are logged but don't crash the app

## Backend Setup

### OrignaBase Config Endpoint

The app expects a `/config/min_app_version` endpoint that returns:
```json
{
  "value": "1.2.0"
}
```

This endpoint is already available via the public config system. The admin can set it via the OrignaBase dashboard:
1. Navigate to Admin Panel → Config
2. Create/edit config key: `min_app_version`
3. Set value: semantic version string (e.g., `"1.1.0"`, `"2.0.0"`)

## Translations

Added to both `assets/translations/en.json` and `assets/translations/fr.json`:

```json
"app": {
  "update_required_title": "Update Required",
  "update_required_message": "A new version ({}) is required. Please update to continue.",
  "update_now": "Update Now"
}
```

French (Quebec Bill 96 / Loi 96 compliance):
```json
"app": {
  "update_required_title": "Mise à jour requise",
  "update_required_message": "Une nouvelle version ({}) est requise. Veuillez mettre à jour pour continuer.",
  "update_now": "Mettre à jour"
}
```

## Behavior

1. **On App Launch** (mobile/tablet only):
   - After first frame renders, `AppUpdateService.checkForUpdate()` is called
   - Async operation with 5-second timeout
   - Network errors are silently caught and logged

2. **Update Required**:
   - Non-dismissible dialog appears
   - User must tap "Update Now" to open the app store
   - Dialog blocks all other app interaction

3. **No Update Required**:
   - App continues normally
   - Check runs silently in background

## Testing

The version check is tested in the test suite:
- Handles missing platform implementations gracefully (test environment)
- Handles network errors
- Parses semantic versions correctly

Run tests with:
```bash
flutter test --exclude-tags golden
```

## Future Improvements

- [ ] Replace store URLs with actual app IDs when apps are published
- [ ] Add analytics tracking for update prompts
- [ ] Consider soft-update vs force-update (optional vs mandatory)
- [ ] Add version changelog display in dialog
