# stay_manager

A **configuration-driven** property / homestay management application for small
properties (hotels, guest houses, homestays) built with **Flutter** and
**Firebase**.

The app is intentionally *generic*: it ships with **no hard-coded property name,
address, phone number, room numbers, prices, currency, tax rate, logo or business
information**. Everything that is property-specific is loaded from configuration
data (Firestore) at runtime, so the same codebase can be reused for any property.

> Built following the master specification in
> [`docs/DEVELOPMENT_PROMPT.md`](docs/DEVELOPMENT_PROMPT.md).

---

## Table of contents

- [Overview](#overview)
- [Current status](#current-status)
- [Tech stack](#tech-stack)
- [App navigation](#app-navigation)
- [Project structure](#project-structure)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Firebase setup (Phase 11)](#firebase-setup-phase-11)
- [Running & verifying](#running--verifying)
- [Testing](#testing)
- [Roadmap](#roadmap)
- [Planned data model (Firestore)](#planned-data-model-firestore)
- [Booking calculation rules](#booking-calculation-rules)
- [Security model](#security-model)
- [Coding conventions](#coding-conventions)
- [Documentation](#documentation)
- [License](#license)

---

## Overview

`stay_manager` targets a very common small-property setup:

- **One property**, roughly **9 rooms** to start.
- **Two Android phones** — one **ADMIN** device, one **STAFF** device.
- Low concurrency: usually only one person creates/modifies a booking at a time.
- **No computer on-site** — the phones *are* the system.
- Data **synchronizes automatically** between phones through Cloud Firestore.
- Must keep working (create bookings, record payments) when the **internet is
  temporarily unavailable** — Firestore offline persistence handles this.

The design deliberately leaves room to grow into multi-property, more rooms,
extra staff, OTA integrations, payment gateways, invoices, GST configuration,
advanced reporting and notifications — but **those are not implemented until
explicitly requested** (see the spec's incremental development rule).

---

## Current status

| Phase | Description | Status |
| ----- | ----------- | ------ |
| **1** | **Project foundation** (theme, shell, navigation, folder structure) | ✅ **Done** |
| **2** | **Configuration** (Property/Room/Settings models, repository + state, config screens, seeded property + rooms) | ✅ **Done** |
| **3** | Dashboard (occupancy, arrivals/departures, revenue, outstanding) | ✅ **Done** |
| **4** | Rooms (list, status) | ✅ **Done** (details + block/unblock pending) |
| **5** | Guests (list, search, details, history) | ✅ **Done** |
| **6** | Bookings (list, create/edit, details, availability, calculations) | ✅ **Done** |
| **7** | Payments (record, history, outstanding, modes) | ✅ **Done** |
| **8** | Check-in / Check-out (status transitions, audit) | ✅ **Done** |
| 9 | Expenses & Cash management | ⬜ Planned |
| 10 | Reports (daily, monthly, room-wise, payment-wise) | ⬜ Planned |
| 11 | Firebase (auth, Firestore repositories, rules, offline) | ⬜ Planned |
| 12 | Multi-device testing (Phone A ⇄ Firestore ⇄ Phone B) | ⬜ Planned |
| 13 | Production hardening (errors, security, perf, release build) | ⬜ Planned |

### What works today (Phases 1–8)

- Material 3 light theme built from a single seed color.
- Application shell with a Material 3 `NavigationBar` (bottom navigation).
- Four top-level destinations: **Dashboard, Rooms, Bookings, More**.
- **Configuration layer**: `Property`, `Room`, `AppSettings` models (Firestore-ready
  `fromMap`/`toMap`), `RoomStatus` / `PaymentMode` / `BookingSource` enums.
- **Repository + state**: `ConfigRepository` and `OperationsRepository`
  interfaces with in-memory implementations, `ConfigController` /
  `OperationsController` (`ChangeNotifier`) and `ConfigScope` /
  `OperationsScope` (`InheritedNotifier`) — no third-party state management.
- **Config screens** under *More*: **Property setup** and **Room setup**
  (add/edit/delete rooms, type, floor, occupancy, base price, status).
- **Booking a room**: the **Bookings** tab has a *New booking* action that
  opens a single form for **guest details, dates, room, occupancy and pricing**.
  Guests can be searched or created inline without leaving the form.
- **Availability validation** — unavailable rooms are shown but disabled, and
  `AvailabilityService` rejects overlapping bookings centrally.
- **Live price breakdown** — nights, discount, tax and total recalculate as you
  type, driven by `BookingCalculator` (never computed in a widget).
- **Check-in / check-out** with room status transitions and audit fields,
  governed by the configurable `checkoutRequiresSettlement` policy.
- **Payments** — record against a booking (amount pre-filled with the
  outstanding balance), full history, and automatic balance recalculation.
- **Dashboard** — occupancy, today's arrivals/departures, revenue, cash, online,
  expenses, outstanding, plus recent bookings.
- **Config-driven UI** — the property name, currency, tax rate, room types,
  payment modes, booking sources and expense categories are all read from
  configuration; none are hard-coded.
- **Utilities**: form validators, money formatter, map parsing helpers,
  availability, booking/payment/report calculators, status chips.
- **40 tests** covering calculators, availability, models, seed data,
  navigation and the booking/guest-entry flow.

### Not yet implemented (by design)

- ❌ Firebase Auth / Firestore / `firebase_options.dart` — intentionally deferred
  to Phase 11 (the in-memory repositories are drop-in behind `ConfigRepository`
  and `OperationsRepository`).
- ❌ Expenses & cash management (Phase 9) and the reports screen (Phase 10) —
  the aggregation logic (`ReportCalculator`, cash-session figures) already
  exists and is unit-testable; only the screens are missing.
- ❌ Room details screen and manual block/unblock (remainder of Phase 4).
- ❌ Any hard-coded business logic in widgets — property values live only in the
  seed data file and are always read through `ConfigScope` / `OperationsScope`.

### How to take a booking (quick start)

1. **Bookings** tab → tap **New booking**.
2. Tap **Select guest** → search for an existing guest, or tap
   **New guest details** to enter name, phone, email, address and ID.
3. Pick **check-in / check-out** dates.
4. Tap **Select room** — available rooms are selectable, occupied ones are
   shown greyed out with the reason.
5. Enter adults/children and the nightly price (pre-filled from the room's
   configured base price), optionally a discount.
6. Watch the **Summary** card update live, then tap **Create booking**.
7. Open the booking to **check in**, **record payment** and **check out**.

---

## Tech stack

| Area | Choice |
| ---- | ------ |
| Language | Dart (SDK `^3.13.4`), null-safe |
| Framework | Flutter |
| UI | Material 3 (`useMaterial3: true`) |
| Primary target | Android |
| Dev target | Chrome / Web |
| Auth (planned) | Firebase Authentication (email/password) |
| Database (planned) | Cloud Firestore with offline persistence |
| Firebase project (planned) | `stay-manager-dev` |
| Lints | `flutter_lints` |
| IDE | VS Code |

Backend alternatives (Spring Boot, PostgreSQL, Azure, custom REST servers,
WhatsApp-based sync) are **explicitly out of scope** — Firestore is the single
source of truth for synchronization and offline caching.

---

## App navigation

Mobile-first, four tabs at the bottom:

```text
Dashboard | Rooms | Bookings | More
```

The **More** section is the entry point for the secondary features:

```text
Guests · Payments · Expenses · Reports · Settings · Users
```

Admin-only screens (property/room/user configuration) will be gated by role
(`ADMIN` / `STAFF`) once authentication lands in Phase 11.

---

## Project structure

The codebase follows the layered structure from the specification. Folders are
created as their features arrive, keeping the tree honest about what actually
exists.

```text
lib/
├── main.dart                      # Bootstraps ConfigController, runs the app
├── app/
│   ├── app.dart                   # ConfigScope + MaterialApp + AppShell (bottom nav)
│   ├── router/                    # (planned) routing
│   └── theme/
│       └── app_theme.dart         # Material 3 theme from a seed color
├── core/
│   ├── constants/
│   │   └── app_defaults.dart      # Generic default lists (types, modes, sources)
│   ├── errors/                    # (planned) failure types
│   ├── extensions/                # (planned) Dart/Flutter extensions
│   ├── utils/
│   │   ├── map_utils.dart         # Safe map → typed value parsing
│   │   ├── money_format.dart      # Currency-code-aware amount formatting
│   │   └── validators.dart        # Reusable form validators
│   └── widgets/
│       ├── room_status_chip.dart  # Status chip styled per RoomStatus
│       ├── section_placeholder.dart  # Reusable empty/placeholder state
│       └── status_chip.dart       # Generic pill label
├── features/
│   ├── dashboard/
│   │   ├── dashboard_page.dart      # Occupancy, arrivals, departures, revenue
│   │   └── dashboard_widgets.dart   # Metric cards, money rows, booking lists
│   ├── rooms/rooms_page.dart        # Configured rooms list
│   ├── bookings/
│   │   ├── bookings_page.dart       # Booking list + status filters
│   │   ├── booking_form_page.dart   # Guest, stay, occupancy, pricing
│   │   ├── booking_details_page.dart# Check-in/out, payment, cancel actions
│   │   └── booking_widgets.dart     # Info/money rows, action buttons
│   ├── guests/
│   │   ├── guests_page.dart         # Searchable guest list
│   │   ├── guest_details_page.dart  # Profile + booking history
│   │   ├── guest_form_page.dart     # Create/edit guest details
│   │   └── guest_picker_sheet.dart  # Pick or create inline while booking
│   ├── payments/
│   │   ├── payments_page.dart       # Collection history
│   │   └── payment_form_page.dart   # Record a payment
│   ├── operations/
│   │   ├── operations_controller.dart # State + business orchestration
│   │   └── operations_scope.dart      # Provides it to the widget tree
│   ├── settings/
│   │   ├── settings_page.dart          # "More" hub (config + operations)
│   │   ├── config_controller.dart      # Config state (ChangeNotifier)
│   │   ├── config_scope.dart           # Provides ConfigController to the tree
│   │   ├── property_setup_page.dart    # Property configuration form
│   │   ├── rooms_setup_page.dart       # Room list (add/edit/delete)
│   │   └── room_form_page.dart         # Create/edit a single room
│   ├── expenses/    (planned)
│   ├── reports/     (planned)
│   └── auth/        (planned)
├── data/
│   ├── config/
│   │   └── property_seed.dart     # Seed property + 9 rooms (data, not logic)
│   ├── models/
│   │   ├── property.dart          # Property configuration model
│   │   ├── room.dart              # Room model
│   │   ├── app_settings.dart      # Configurable lists + policy
│   │   ├── app_user.dart          # User profile + ADMIN/STAFF role
│   │   ├── guest.dart             # Guest profile
│   │   ├── booking.dart           # Stay + money fields
│   │   ├── payment.dart           # A single collection record
│   │   ├── expense.dart           # Operating expense
│   │   ├── cash_session.dart      # Opening/counted cash per day
│   │   ├── room_status.dart       # RoomStatus enum
│   │   ├── booking_status.dart    # BookingStatus enum
│   │   ├── payment_status.dart    # PaymentStatus enum
│   │   ├── payment_mode.dart      # PaymentMode enum
│   │   └── booking_source.dart    # BookingSource enum
│   └── repositories/
│       ├── config_repository.dart           # Abstraction (Firestore-ready)
│       ├── in_memory_config_repository.dart # Phase 2 implementation
│       ├── operations_repository.dart       # Operational data abstraction
│       ├── in_memory_operations_repository.dart
│       └── room_status_writer.dart          # Room-status seam for operations
└── firebase_options.dart (planned — generated in Phase 11)

test/
├── widget_test.dart                   # Navigation + booking/guest entry flow
├── core/
│   ├── utils_test.dart                # Validators + money formatting
│   └── booking_builder_test.dart      # Booking/payment/availability rules
└── data/
    ├── models_test.dart              # Model serialization + enum mapping
    └── config_seed_test.dart         # Seed completeness

docs/
└── DEVELOPMENT_PROMPT.md          # The master specification / build prompt
```

---

## Architecture

Guiding principles (from the spec):

- **UI ≠ business logic.** Widgets render; calculations and rules live in
  `core/utils` and `data/`.
- **Repository / service pattern** for all data access — both phones read/write
  the *same* Firestore source, so synchronization is automatic.
- **Strong typing + null safety**, small reusable widgets, meaningful names, no
  magic numbers.
- **No hard-coded business data.** Property, rooms, currency, tax, payment modes
  and booking sources are all configuration, loaded at runtime.
- **Prefer simple over clever.** No unnecessary abstraction, no extra backend.

Planned layering once data features arrive:

```text
Widget (features/*)  →  Repository (data/repositories)  →  Firestore
                              ↑
                    Models (data/models) + Pure calculators (core/utils)
```

State management stays minimal and Flutter-native for now; the emphasis is on
keeping data access behind repositories so the UI can be tested in isolation.

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.13.4`).
- VS Code with the **Dart** and **Flutter** extensions.
- For Android builds: Android SDK / a connected device or emulator.
- **Google Chrome** for the quickest web-based dev loop (`flutter run -d chrome`).
  Enable it once with `flutter config --enable-web` if web is not yet listed by
  `flutter doctor`.

Verify your toolchain:

```powershell
flutter --version
flutter doctor
```

### Install dependencies

```powershell
flutter pub get
```

`firebase_core`, `cloud_firestore` and `firebase_auth` are now added (Phase 11
in progress). See [Firebase setup](#firebase-setup-phase-11) for the console
steps and the FlutterFire CLI.

---

## Firebase setup (Phase 11)

Everything except the console clicks is already in place. The app **still runs
without Firebase** — it falls back to the in-memory repositories — so you can
do this at your own pace.

### 1. Create the Firebase project

1. Go to <https://console.firebase.google.com> and sign in with a **Google
   account** (a new one is fine — you do not need a paid plan; the Spark plan
   is enough for a small property).
2. Click **Add project**.
   - Project name: `stay-manager-dev` (as in the specification)
   - Google Analytics: **disable** it (not needed for this app)
3. When the project is ready, note the **Project ID** (it may differ slightly
   from the name).

### 2. Create a Firestore database

1. In the console, go to **Build → Firestore Database**.
2. Click **Create database**.
3. Choose **Start in production mode** — the
   [`firestore.rules`](firestore.rules) in this repo already denies everything
   by default, so production mode is the safe choice.
4. Pick a location close to your property (e.g. `asia-south1 (Mumbai)`).

### 3. Enable Authentication

1. Go to **Build → Authentication**.
2. Click **Get started**.
3. Under **Sign-in method**, enable **Email/Password**
   (the spec deliberately avoids SMS/phone auth to keep cost and complexity
   down).
4. Click **Save**.

### 4. Install the FlutterFire CLI

This is the official tool that generates `firebase_options.dart` and registers
the Android app.

```powershell
# 1. Install (requires Node.js, already present as v22)
dart pub global activate flutterfire_cli

# 2. Add the pub cache bin folder to PATH for this session
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"

# 3. Verify
flutterfire --version
```

> If step 3 fails, restart your terminal, or add
> `%LOCALAPPDATA%\Pub\Cache\bin` to your system PATH permanently.

### 5. Connect the project

From `c:\Development\hotel-management\stay_manager`:

```powershell
flutterfire configure `
  --project=stay-manager-dev `
  --platforms=android,web `
  --android-package-name=com.example.stay_manager `
  --android-language=kotlin
```

This will:

- sign you in to Firebase
- download **`google-services.json`** into `android/app/`
- generate **`lib/firebase_options.dart`**
- register the Android app in the project

Accept the defaults for anything not specified above.

### 6. Verify

```powershell
flutter analyze
flutter run -d chrome
```

Once `firebase_options.json` / `google-services.json` exist,
`FirebaseBootstrap.initialize()` succeeds and `main.dart` automatically swaps
the in-memory repositories for the Firestore-backed ones — **no other code
changes required**.

### 7. Deploy the security rules

Rules in this repo are only local until deployed:

```powershell
# Install the CLI once (requires Node.js)
npm install -g firebase-tools

# Log in and deploy the rules
firebase login
firebase use --add          # pick stay-manager-dev
firebase deploy --only firestore:rules
```

The rules enforce what the spec requires:

| Rule | Effect |
| ---- | ------ |
| Unauthenticated | Cannot read or write any business data |
| Property isolation | Every query/document is scoped to the caller's `propertyId` |
| `ADMIN` | Full access: configuration, rooms, users, expenses, reports |
| `STAFF` | Operational only: bookings, payments, guests, room status |
| Default deny | Anything not explicitly allowed is refused |

> UI hiding is **never** the security boundary — the rules are.

### Notes and troubleshooting

- **`firebase_options.dart` contains no secrets**, but it is
  environment-specific. It is safe to commit, or add it to `.gitignore` if you
  prefer. `google-services.json` is likewise not a secret for Android, but keep
  it out of public repositories anyway.
- **Windows symlink warning** during `pub add`: enable
  **Developer Mode** (Settings → System → For developers) or run PowerShell as
  Administrator. It only affects local tooling, not the app.
- **Offline behaviour**: Firestore's offline cache means the app keeps working
  without internet and syncs automatically when connectivity returns.
- **Seeded data**: the first run provisions the sample property and 9 rooms from
  [`lib/data/config/property_seed.dart`](lib/data/config/property_seed.dart),
  which you can then edit in *More → Property setup*.

## Running & verifying

### Run in Chrome (fastest development loop)

Chrome is the recommended target for day-to-day development on this machine —
it starts quickly and hot reloads without an emulator.

```powershell
# 1. From the project root
cd c:\Development\hotel-management\stay_manager

# 2. Make sure Chrome / web support is enabled
flutter config --enable-web
flutter doctor

# 3. Confirm Chrome is detected
flutter devices

# 4. Run the app
flutter run -d chrome
```

Useful variations:

```powershell
# Skip the debug banner and expose the VM service for DevTools
flutter run -d chrome --no-dds

# Run on a different web browser (Edge is also installed)
flutter run -d edge

# Open on a specific port (handy when the default 8080/3000 is busy)
flutter run -d chrome --web-port 8081

# Release build served statically (closer to production behaviour)
flutter build web --release
# then open build\web\index.html, or serve it with:
#   cd build\web ; python -m http.server 8080
```

While `flutter run -d chrome` is active, use these in the terminal:

| Key | Action |
| --- | ------ |
| `r` | Hot reload (fastest loop, keeps app state) |
| `R` | Hot restart (rebuilds state, e.g. after changing controllers) |
| `q` | Quit the app |

> Chrome must be able to reach the Dart debug server. If hot reload stalls,
> press `R` (hot restart) first; if the page shows a stale build, stop with `q`
> and re-run the command.

### Run on Android (primary target)

```powershell
# With a connected device or a running emulator
flutter devices
flutter run -d android

# List available emulators (Android Studio AVDs)
flutter emulators
```

### Verify before committing

```powershell
flutter analyze   # must stay warning- and error-free
flutter test      # unit + widget tests
```

### Build a release artifact (Phase 13)

```powershell
flutter build apk --release
# or
flutter build appbundle --release
```

Release artifacts are written to `build\app\outputs\flutter-apk\` and
`build\app\outputs\bundle\`.

---

## Testing

`flutter test` currently runs **40 tests** covering:

| Area | Cases |
| ---- | ----- |
| `test/core/booking_builder_test.dart` | Booking calculation: 1 night, multiple nights, discount, tax, no tax, invalid dates, negative/over-subtotal discount; payment calculation: none, partial, full, multiple, over-outstanding rejection; availability: free, booked, non-overlapping, blocked, cancelled; `BookingBuilder` pricing and validation |
| `test/core/utils_test.dart` | Validators (required, percentage, positive int, time, email) and money formatting |
| `test/data/models_test.dart` | Model `fromMap`/`toMap` round-trips, tolerance of malformed data, enum wire mapping |
| `test/data/config_seed_test.dart` | Seed property and room completeness |
| `test/widget_test.dart` | Navigation between sections, opening the booking form, entering guest details inline |

Planned additions as later phases land: expense/cash and report aggregation
tests, plus UI tests for check-in/out and payment screens.

Run them with:

```powershell
flutter test
# single file
flutter test test/core/booking_builder_test.dart
```

---

## Roadmap

The build proceeds phase-by-phase. Each phase ends with `flutter analyze`, tests,
a manual UI check, and a short report — then we wait for approval before moving
on (spec §29).

1. **Phase 1 — Foundation** ✅ — Material 3 theme, app shell, bottom navigation,
   folder structure, placeholder pages, git baseline.
2. **Phase 2 \u2014 Configuration** \u2705 \u2014 `Property`, `Room`, `Settings` models and
   configuration screens (generic property setup).
3. **Phase 3 \u2014 Dashboard** \u2705 \u2014 occupancy, arrivals/departures, revenue, cash,
   online, expenses and outstanding.
4. **Phase 4 \u2014 Rooms** \u2705 \u2014 room list with live status chips (details and
   manual block/unblock still to come).
5. **Phase 5 \u2014 Guests** \u2705 \u2014 list, search, details, booking history.
6. **Phase 6 \u2014 Bookings** \u2705 \u2014 list with status filters, create/edit with
   availability validation and live calculations, details.
7. **Phase 7 \u2014 Payments** \u2705 \u2014 record a payment, history, outstanding, modes.
8. **Phase 8 \u2014 Check-in / Check-out** \u2705 \u2014 room/booking status transitions,
   audit fields, configurable settlement policy.
9. **Phase 9 \u2014 Expenses & Cash** \u2b1c \u2014 next. Aggregation logic already exists.
10. **Phase 10 \u2014 Reports** \u2b1c \u2014 daily, monthly, room-wise, payment-wise.
11. **Phase 11 \u2014 Firebase** \u2b1c \u2014 Firebase config, authentication, Firestore
     repositories, security rules, offline persistence.
12. **Phase 12 \u2014 Multi-device testing** \u2b1c \u2014 Phone A \u21c4 Firestore \u21c4 Phone B, and
     offline \u2192 online sync.
13. **Phase 13 \u2014 Production hardening** \u2b1c \u2014 error handling, security review,
     performance, validation, tests, release APK/AAB.

---

## Planned data model (Firestore)

Multi-property-ready collections (introduced from Phase 2 / 11):

```text
properties/{propertyId}     # name, address, phone, email, currency, timezone,
                            # taxEnabled, taxPercentage, checkInTime,
                            # checkOutTime, logoUrl, active

users/{userId}              # displayName, email, role (ADMIN|STAFF),
                            # propertyId, active, createdAt, updatedAt

rooms/{roomId}              # propertyId, roomNumber, name, type, floor,
                            # maxOccupancy, basePrice, status, active

guests/{guestId}            # propertyId, name, phone, email, address,
                            # idType, idNumber, notes

bookings/{bookingId}        # propertyId, guestId, roomId, guestName, guestPhone,
                            # adults, children, checkInDate, checkOutDate,
                            # pricePerNight, numberOfNights, subtotal, discount,
                            # tax, total, advancePaid, outstandingAmount,
                            # paymentStatus, bookingStatus, source, notes

payments/{paymentId}        # propertyId, bookingId, guestId, amount, paymentMode,
                            # reference, notes, paymentDate

expenses/{expenseId}        # propertyId, date, amount, category, paymentMode,
                            # description

settings/{settingId}        # configurable lists (room types, sources, modes…)
```

Every operational document carries audit fields:
`createdAt`, `updatedAt`, `createdBy`, `updatedBy`, `propertyId`
(server timestamps where appropriate).

**Room statuses:** `AVAILABLE`, `BOOKED`, `CHECKED_IN`, `CHECKED_OUT`,
`CLEANING`, `BLOCKED`.

**Booking sources (defaults, configurable):** `WALK_IN`, `PHONE`, `WHATSAPP`,
`WEBSITE`, `BOOKING_COM`, `MAKEMYTRIP`, `AGODA`, `OTHER`.

**Payment modes (defaults, configurable):** `CASH`, `UPI`, `CARD`,
`BANK_TRANSFER`, `OTHER`.

---

## Booking calculation rules

Calculations are centralized (planned for `core/utils`) and unit-tested — never
computed inside widgets:

```text
numberOfNights = checkOutDate - checkInDate
subtotal       = pricePerNight * numberOfNights
taxableAmount  = subtotal - discount
tax            = taxableAmount * taxPercentage
total          = taxableAmount + tax
outstanding    = total - totalPayments
```

Guards required:

- Reject negative discounts and negative payments.
- Reject check-out on/before check-in (zero/negative nights).
- Prevent payments exceeding outstanding unless explicitly permitted.
- Validate room availability (respecting room status) before booking.

---

## Security model

Firestore security rules (Phase 11) must enforce — *not* rely on UI hiding:

- **Authentication:** unauthenticated users cannot read/write business data.
- **Property isolation:** users only access data for their assigned `propertyId`.
- **ADMIN:** manage property config, rooms, users, bookings, payments, expenses;
  view reports.
- **STAFF:** view rooms, create/update bookings, check guests in/out, record
  payments, view operational data.

No secrets in source control; `google-services.json` / `firebase_options.dart`
handling will be documented when Firebase lands.

---

## Coding conventions

- Null-safe, strongly typed Dart; `flutter analyze` must stay clean.
- Material 3 widgets and theme tokens; no hard-coded colors/sizes scattered in
  widgets.
- One feature per folder under `lib/features/<feature>/`.
- Shared, reusable UI under `lib/core/widgets/`.
- Business rules and math in `core/utils` / `data/`, covered by unit tests.
- Repository pattern for all Firestore access.
- Handle loading, empty, error and retry states for every data-backed screen.
- Never hard-code property-specific information.

---

## Documentation

| Document | Purpose |
| -------- | ------- |
| [`docs/DEVELOPMENT_PROMPT.md`](docs/DEVELOPMENT_PROMPT.md) | The full master specification / development prompt that drives this build |
| `README.md` | This file — overview, structure, how to run |

---

## License

Private project — not intended for publication. See `pubspec.yaml`
(`publish_to: 'none'`).
