# PacePal - MVC Architecture

## Project Structure

This project follows a feature-based MVC architecture with clear separation of concerns.

### pacepal/ (Main App Directory)
- `ContentView.swift` - Main content view
- `Configuration.plist` - Environment variables
- `Configuration.example.plist` - Environment variables template

### Screens/ (Feature Modules)
Each feature has its own folder with dedicated subfolders:

#### Login/
- **Screens/**: `pacepalApp.swift` (main app entry point)
- **Views/**: `LoginView.swift`, `LandingView.swift`, `LoadingView.swift`
- **Models/**: Login-specific data models (currently empty)
- **Logic/**: Login-specific business logic (currently empty)

#### Home/
- **Screens/**: Home screen controllers (currently empty)
- **Views/**: `HomeView.swift`, `StatsView.swift`, `AppIconView.swift`
- **Models/**: Home-specific data models (currently empty)
- **Logic/**: Home-specific business logic (currently empty)

#### Coupon/
- **Screens/**: Coupon screen controllers (currently empty)
- **Views/**: `CouponView.swift`
- **Models/**: Coupon-specific data models (currently empty)
- **Logic/**: Coupon-specific business logic (currently empty)

#### Store/
- **Screens/**: Store screen controllers (currently empty)
- **Views/**: `StoreView.swift`
- **Models/**: Store-specific data models (currently empty)
- **Logic/**: Store-specific business logic (currently empty)

### Core/ (Shared Components)

#### Models/
- `ActiveCreature.swift` - Active creature management
- `AppStore.swift` - App state management
- `Creature.swift` - Creature data model
- `CreatureProfile.swift` - Creature profile data
- `Farm.swift` - Farm management
- `FoodItem.swift` - Food item data model
- `Run.swift` - Run data model

#### Views/
- `CreatureView.swift` - Reusable creature display component
- `EggSelectionView.swift` - Egg selection interface
- `EvolutionPopupView.swift` - Evolution celebration popup

#### Logic/
- `ConfigurationService.swift` - Environment configuration
- `KeychainService.swift` - Secure storage
- `StatsCache.swift` - Statistics caching
- `StravaAPIClient.swift` - Strava API integration
- `StravaAuthService.swift` - Strava authentication
- `SyncService.swift` - Data synchronization

#### Utilities/
- `ColorExtensions.swift` - Color utilities and theme

## Architecture Principles

### Models
- **Purpose**: Data, entities, DTOs, persistence objects
- **Location**: Feature-specific in `Screens/[Feature]/Models/` or shared in `Core/Models/`
- **Rules**: Pure data structures, no business logic

### Views
- **Purpose**: UI components (SwiftUI Views, custom components, reusable elements)
- **Location**: Feature-specific in `Screens/[Feature]/Views/` or shared in `Core/Views/`
- **Rules**: UI only, minimal logic, reusable when possible

### Controllers (Screens)
- **Purpose**: SwiftUI Views that connect Views + Logic
- **Location**: `Screens/[Feature]/Screens/`
- **Rules**: Coordinate between Views and Logic, no heavy business logic

### Logic
- **Purpose**: Business logic, networking, services, managers
- **Location**: Feature-specific in `Screens/[Feature]/Logic/` or shared in `Core/Logic/`
- **Rules**: Contains all business logic, controllers should not contain heavy logic

### Core
- **Purpose**: Central place for code reused across multiple features
- **Location**: `Core/`
- **Rules**: Shared models, views, services, utilities

## Benefits

1. **Clear Separation**: Each feature is self-contained
2. **Reusability**: Shared components in Core
3. **Maintainability**: Easy to find and modify feature-specific code
4. **Scalability**: Easy to add new features
5. **Testing**: Clear boundaries for unit testing

## Migration Notes

- All files have been moved to their appropriate locations
- Import statements remain the same (same module)
- No breaking changes to existing functionality
- Ready for future feature-specific enhancements
