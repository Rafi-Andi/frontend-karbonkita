# AGENTS.md

## Quick Commands (run with workdir `KarbonKitaFrontend/`)
- `flutter analyze` — lint check (required before commits); single file: `flutter analyze lib/ui/screens/<file>.dart`
- `dart format <path>` — formatter (required before commits). NOTE: `flutter format` does not exist in this toolchain
- `flutter test` — run tests
- `flutter run` — local dev server

## Architecture
- **State management**: flutter_bloc (BLoC/Cubit pattern)
- **Networking**: dio
- **Storage**: shared_preferences (non-sensitive), flutter_secure_storage (tokens/passwords)
- **See CONTRIBUTING.md** for full coding rules (file naming, separation of concerns, widget extraction)

## Directory Layout
- `lib/bloc/` — BLoC/Cubit state management (currently empty)
- `lib/models/` — data models, fromJson/toJson (currently empty)
- `lib/services/` — API service, Dio client (currently empty)
- `lib/ui/screens/` — page-level widgets
- `lib/ui/widgets/` — reusable components (currently empty)
- `lib/main.dart` — app entry point

## Current State (Early Stage)
- Screens have UI code but no BLoC wiring — business logic is not yet implemented
- `bloc/`, `models/`, `services/` directories are scaffolded but empty
- App flow: `main.dart` → `LoginScreen` → `HomeScreen` (5-tab bottom nav); `MarketplaceScreen` → `DompetVoucherScreen` (ticket cards + QR redeem bottom sheet)

## Conventions
- File names: snake_case
- Class names: PascalCase
- Variables/functions: camelCase
- Extract widgets to `ui/widgets/` when `build()` exceeds ~100 lines
- Assets in `assets/images/` — code uses `errorBuilder` fallbacks for missing images
- New code: use `color.withValues(alpha: x)` — `withOpacity` is deprecated (old files still use it; don't mass-migrate)
- Never fix card/ticket height with a hardcoded `height:` — size cards from content (`Stack` + `Positioned.fill`, `mainAxisSize.min`) or long text overflows on small screens
