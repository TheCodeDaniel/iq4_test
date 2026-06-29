# IQ Test — Flutter Product Listing App

A Flutter mobile application that fetches, caches, and displays product/transaction data from a REST API. It features a PIN lock authentication screen, paginated product listings with search and category filtering, offline-first caching, and a polished UI with shimmer loading states.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Architecture & Design Patterns](#architecture--design-patterns)
- [State Management](#state-management)
- [Data Layer](#data-layer)
- [Key Features & Flows](#key-features--flows)
- [Dependencies](#dependencies)
- [Core Utilities](#core-utilities)
- [Reusable UI Widgets](#reusable-ui-widgets)

---

## Quick Start

### Prerequisites

- **Flutter SDK**: `^3.11.4` or later
- **Dart SDK**: bundled with Flutter
- An Android device/emulator or iOS simulator (or a physical device)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/TheCodeDaniel/iq4_test.git
cd iq4_test

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

---

## Project Structure

The project follows a **feature-based folder structure** that groups related code together:

```
lib/
├── main.dart                          # App entry point & route configuration
│
├── core/                              # Shared / cross-cutting concerns
│   ├── extensions/
│   │   ├── context_extensions.dart    # Utility methods on BuildContext
│   │   └── navigation_extensions.dart # Simplified navigation helpers
│   │
│   ├── services/
│   │   ├── api/
│   │   │   ├── api_constants.dart     # API endpoint definitions
│   │   │   ├── api_functions.dart     # HTTP call helper wrapper
│   │   │   └── api_handler.dart       # Error filtering & response handling
│   │   └── local_storage/
│   │       └── product_cache_services.dart   # Hive-based caching layer
│   │
│   └── widgets/                       # Reusable UI components
│       ├── cache_banner.dart          # "Updated X min ago" banner
│       ├── cached_image.dart          # Network image with cache + shimmer
│       ├── custom_pin_screen.dart     # PIN input widget
│       ├── empty_state.dart           # Empty list placeholder
│       ├── error_state.dart           # Error retry UI
│       ├── price_tag.dart             # Price display with discount
│       ├── product_card.dart          # Compact product card
│       ├── rating_bar.dart            # Star rating widget
│       ├── shimmer_loading.dart       # Skeleton loading animation
│       └── staggered_list_item.dart   # Masonry grid item wrapper
│
└── features/                          # Feature modules
    ├── auth/
    │   └── pin_lock_view.dart         # PIN lock authentication screen
    │
    └── transactions/                  # Product listing feature
        ├── data/
        │   ├── models/
        │   │   └── product_model.dart # Product + ProductsResponse models
        │   └── repository/
        │       └── products_repository.dart   # Data abstraction layer
        │
        ├── presentation/
        │   ├── bloc/
        │   │   ├── product_events.dart  # Product events
        │   │   ├── products_bloc.dart   # Main BLoC
        │   │   └── products_state.dart  # Product states enum + class
        │   │
        │   ├── views/
        │   │   ├── product_details_view.dart    # Detail page
        │   │   └── transactions_list_view.dart  # Main list page
        │   │
        │   └── widgets/
        │       ├── info_row.dart                # Label + value row
        │       ├── product_image_gallery.dart   # Scrollable image viewer
        │       ├── products_list_view.dart      # Custom scroll physics list
        │       └── stock_badge.dart             # In-stock / out-of-stock badge
```

### Why this structure?

- **Feature isolation**: Each feature (`auth`, `transactions`) owns its data, presentation, and business logic. Adding a new feature means adding a new folder — no existing code needs to be touched.
- **Shared code in `core/`**: APIs, caching, and reusable widgets are kept separate from feature code so they can be reused across features without circular dependencies.

---

## Architecture & Design Patterns

### 1. Clean Architecture (3-layer approach)

```
┌─────────────────────┐
│   Presentation Layer │  ← UI (Views + BLoC + Widgets)
│      (lib/features/  │
│       transactions/) │
├─────────────────────┤
│    Domain / Logic    │  ← Repository interface, business rules
│      (Repository)    │
├─────────────────────┤
│     Data Layer       │  ← Models, API calls, Hive caching
│   (Models + Repo impl│    + ApiFunction service)
└─────────────────────┘
```

### 2. Repository Pattern

The `ProductRepository` class abstracts where data comes from. The rest of the app doesn't know or care whether a product came from the network, cache, or both — it just requests products and gets results.

### 3. Cache-First Strategy

When fetching products:

1. **Check Hive cache** → if found, return immediately (instant UI)
2. **Fetch from API in background** → update cache silently
3. **If API fails** → fall back to cached data (graceful degradation)

This ensures the app feels fast even on slow networks.

### 4. Dependency Injection (Simple)

Repository constructors accept optional `ApiFunction` and `ProductCacheService` parameters, making it easy to inject mock implementations for testing:

```dart
// Production
final repository = ProductRepository();

// Testing
final repository = ProductRepository(
  apiFunction: MockApiFunction(),
  cacheService: MockCacheService(),
);
```

---

## State Management

This project uses **flutter_bloc** — the official state management package recommended by the Flutter team.

### How it works

```
User Action (tap, type, scroll)
        │
        ▼
   EVENT  ──►  BLoC (business logic)
                │
                ▼
            STATE  ──►  UI rebuilds automatically
```

### Events

| Event                   | When it fires                | What it does                                    |
| ----------------------- | ---------------------------- | ----------------------------------------------- |
| `FetchProductsEvent`    | First load / pull-to-refresh | Loads products + categories from API (or cache) |
| `CategoryFilterEvent`   | User taps a category chip    | Filters products by selected category           |
| `SearchProductEvent`    | User types in search bar     | Searches products by query text                 |
| `LoadMoreProductsEvent` | User scrolls near bottom     | Paginates to next page of results               |
| `SelectProductEvent`    | User taps a product card     | Opens the detail view for that product          |

### States

The `ProductsState` class is **immutable** — it uses `copyWith()` to create new states from old ones. This means every property either stays the same or changes intentionally:

```dart
// Example: Adding products while keeping existing state intact
state.copyWith(
  products: [...state.products, ...newProducts],
  isLoadingMore: false,
  hasReachedMax: response.hasMore == false,
)
```

### State Enum

`ProductsStatus` tracks the UI lifecycle:

| Status    | What the user sees            |
| --------- | ----------------------------- |
| `initial` | Nothing loaded yet            |
| `loading` | Shimmer loading skeletons     |
| `loaded`  | Product grid list             |
| `error`   | Error state with retry button |

### Why BLoC?

- **Testability**: Events and states are plain Dart classes (extended `Equatable`). You can unit-test the BLoC by sending events and asserting on emitted states.
- **Separation of concerns**: UI only displays data. All business logic (filtering, pagination, caching) lives in the BLoC.
- **Predictable**: State changes are explicit and traceable through event → state transitions.

---

## Data Layer

### Models

#### `ProductModel`

Represents a single product with these fields:

| Field                 | Type           | Description                 |
| --------------------- | -------------- | --------------------------- |
| `id`                  | `int`          | Unique identifier           |
| `title`               | `String`       | Product name                |
| `description`         | `String`       | Detailed description        |
| `category`            | `String`       | Product category slug       |
| `price`               | `double`       | Original price              |
| `discountPercentage`  | `double`       | Discount percentage (0–100) |
| `rating`              | `double`       | Average rating (0–5)        |
| `stock`               | `int`          | Units available             |
| `brand`               | `String`       | Manufacturer brand          |
| `thumbnail`           | `String`       | Primary image URL           |
| `images`              | `List<String>` | All product images          |
| `availabilityStatus`  | `String`       | Stock status text           |
| `warrantyInformation` | `String`       | Warranty details            |
| `shippingInformation` | `String`       | Shipping details            |
| `returnPolicy`        | `String`       | Return policy info          |
| `tags`                | `List<String>` | Product tags/labels         |

**Computed properties**:

- `discountedPrice` → Calculates the price after discount
- `hasDiscount` → True if discountPercentage > 0
- `isInStock` → True if stock > 0
- `hasPriceAvailable` → True if price > 0

#### `ProductsResponse`

Wraps paginated API responses:

| Field      | Type                 | Description                         |
| ---------- | -------------------- | ----------------------------------- |
| `products` | `List<ProductModel>` | List of products                    |
| `total`    | `int`                | Total number of products available  |
| `skip`     | `int`                | Number of products skipped (offset) |
| `limit`    | `int`                | Number of products per page         |

**Computed property**:

- `hasMore` → Returns `true` if there are more pages to load

### Repository: `ProductRepository`

The repository handles all data operations:

```dart
// Fetch paginated product list (with caching)
final result = await repository.getProducts(limit: 20, skip: 0);

// Search products by query
final searchResults = await repository.searchProducts(query: 'laptop');

// Get products in a specific category
final categoryProducts = await repository.getProductsByCategory(category: 'electronics');

// Fetch a single product by ID
final product = await repository.getProductById(id: 1);

// Get available categories
final categories = await repository.getCategories();

// Clear all cached data
await repository.clearCache();
```

### API Service Layer

Three files handle HTTP communication:

1. **`api_constants.dart`** — Defines endpoint strings (e.g., `/products`, `/products/categories`)
2. **`api_functions.dart`** — A wrapper around Dio that handles GET calls, response parsing, and cancellation tokens
3. **`api_handler.dart`** — Filters API error responses and throws descriptive exceptions

---

## Key Features & Flows

### 1. PIN Lock Authentication

The app starts with a `PinLockView` screen that prompts the user to enter or create a PIN code. This is implemented as a simple screen with custom PIN input widgets from `core/widgets/custom_pin_screen.dart`.

**Flow**:

```
App Launch → PinLockView → Enter/Create PIN → Navigate to main content
```

### 2. Product Listing Flow

The main screen (`TransactionsListView`) displays products in a responsive grid:

```
User opens app
     │
     ▼
┌──────────────┐    ┌───────────────┐
│ BLoC emits   │    │ UI shows      │
│ loading state│ →  │ shimmer cards │
└──────┬───────┘    └───────────────┘
       │
       ▼
Repository checks Hive cache...
     │
     ├── Cache hit → Show cached data immediately + refresh in background
     │
     └── No cache  → Wait for API response → Show products
```

**User interactions**:

- **Pull-to-refresh** → Clears cache and re-fetches all data
- **Tap category chip** → Filters list to that category (emits `CategoryFilterEvent`)
- **Type in search bar** → Searches by product name/query (debounced, emits `SearchProductEvent`)
- **Scroll to bottom** → Loads next page (emits `LoadMoreProductsEvent`), shows shimmer for new items
- **Tap a product card** → Navigates to detail view (emits `SelectProductEvent`)

### 3. Product Detail Flow

```
User taps product card
       │
       ▼
BLoC emits selectedProduct + navigates
       │
       ▼
ProductDetailsView renders with:
  ├── Image gallery (scrollable horizontally)
  ├── Basic info (title, price, rating, stock)
  └── Expandable sections (description, warranty, shipping, returns)
```

### 4. Offline / Error Handling Flow

```
API call fails (no internet, timeout, server error)
       │
       ▼
┌─────────────────────────┐
│ Is there cached data?   │
├────┬──────────┬─────────┤
│ Yes│          │ No      │
│ ▼  │          │ ▼       │
│Show │          │Show     │
|cached│         │error    │
|data │          │state    │
└────┘          └─────────┘
```

The app uses `connectivity_plus` to check network status and displays a `CacheBanner` when showing cached data, informing the user of the last update time.

---

## Dependencies

### Runtime Dependencies

| Package                    | Version | Purpose                               |
| -------------------------- | ------- | ------------------------------------- |
| **dio**                    | ^5.9.2  | HTTP client for making API requests   |
| **flutter_bloc**           | ^9.1.1  | State management (BLoC pattern)       |
| **hive_flutter**           | ^1.1.0  | Local NoSQL database for caching      |
| **cached_network_image**   | ^3.4.1  | Network image loading with disk cache |
| **flutter_secure_storage** | ^10.3.1 | Secure key-value storage (for PIN)    |
| **connectivity_plus**      | ^7.2.0  | Network connectivity monitoring       |
| **shimmer**                | ^3.0.0  | Skeleton loading animations           |
| **fluttertoast**           | ^9.1.0  | Toast notifications                   |
| **iconsax**                | ^0.0.8  | Icon set (Iconsax)                    |
| **intl**                   | ^0.20.3 | Date/time formatting                  |
| **equatable**              | ^2.0.8  | Value-based equality for Dart objects |
| **cupertino_icons**        | ^1.0.8  | iOS-style icons                       |

### Dev Dependencies

| Package           | Purpose                   |
| ----------------- | ------------------------- |
| **flutter_test**  | Flutter testing framework |
| **flutter_lints** | Code linting rules        |

---

## Core Utilities

### Extensions

#### `ContextExtensions` (`lib/core/extensions/context_extensions.dart`)

Provides shortcuts on `BuildContext`:

- Access theme, media queries, and navigation helpers without importing multiple packages

#### `NavigationExtensions` (`lib/core/extensions/navigation_extensions.dart`)

Simplifies routing:

- Provides named route navigation with type safety for views

### Services

#### API Service (`lib/core/services/api/`)

Centralized HTTP handling using Dio:

- Base URL configured in `ApiConstants`
- Automatic error filtering via `apiErrorFilter()`
- Request cancellation support via `CancelToken` (cancels in-flight requests when a new one is made)

#### Local Storage / Cache Service (`lib/core/services/local_storage/product_cache_services.dart`)

Uses **Hive** for persistent key-value storage:

| Cache Key            | Data Stored              | TTL                             |
| -------------------- | ------------------------ | ------------------------------- |
| `all_{limit}_{skip}` | Product list JSON        | Indefinite (cleared on refresh) |
| `categories`         | List of category strings | Indefinite                      |

---

## Reusable UI Widgets

All widgets in `lib/core/widgets/` and `lib/features/transactions/presentation/widgets/` are designed to be composable:

| Widget                | Purpose                                                         |
| --------------------- | --------------------------------------------------------------- |
| `CachedImage`         | Network image with shimmer placeholder + error fallback         |
| `ProductCard`         | Compact card showing product image, title, price, rating        |
| `PriceTag`            | Displays original and discounted prices with discount badge     |
| `RatingBar`           | Interactive or static star rating display (0–5)                 |
| `StockBadge`          | Green "In Stock" / Red "Out of Stock" label                     |
| `ShimmerLoading`      | Animated skeleton placeholder for loading states                |
| `EmptyState`          | Centered illustration + text when no data exists                |
| `ErrorState`          | Error icon, message, and retry button                           |
| `CacheBanner`         | Small banner showing "Updated X min ago" badge                  |
| `StaggeredListItem`   | Wrapper for masonry-style grid items of varying heights         |
| `ProductImageGallery` | Horizontal scrollable image viewer with page indicators         |
| `InfoRow`             | Key-value row (label on left, value on right)                   |
| `ProductsListView`    | Custom scroll view with physics for loading-on-scroll detection |

---

## Getting Started as a Developer

### Adding a New Feature

1. Create a new folder under `lib/features/your_feature_name/`
2. Inside it, create:
   - `data/` — models and repositories
   - `presentation/` — BLoC (events + states), views, widgets
3. Register routes in `main.dart` if the feature has its own screens
4. Import shared widgets from `lib/core/widgets/`

### Running Tests

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart
```

### Code Style

This project uses **flutter_lints** for static analysis. Before committing, run:

```bash
flutter analyze
```

To auto-format code:

```bash
flutter format .
```
