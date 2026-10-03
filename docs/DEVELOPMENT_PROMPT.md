# Generic Property Management App — Master Development Prompt

## 1. Role

Act as a senior Flutter/Dart architect and full-stack mobile engineer.

Build a production-quality **generic property/homestay management Android application**.

The application must be configuration-driven and reusable for different properties. **Do not hard-code any specific property/business name, address, phone number, room numbers, pricing, logo, or business information.**

Work incrementally. Do not rewrite large portions of the project unnecessarily. Keep the application buildable after each major change.

---

# 2. Project

Project directory:

```text
C:\Development\hotel-management\stay_manager
```

Flutter project name:

```text
stay_manager
```

Technology:

* Flutter
* Dart
* Material 3
* Firebase Authentication
* Cloud Firestore
* Firestore offline persistence
* Android as the primary target
* Chrome/Web may be used during development
* VS Code is the primary IDE

Firebase project:

```text
stay-manager-dev
```

---

# 3. Core Product Goal

Build a simple property-management application for a small homestay/hotel.

Typical use case:

* One property
* Approximately 9 rooms initially
* Two Android phones
* One admin user/device
* One staff/operations user/device
* Usually only one person creates or modifies a booking at a time
* No computer available at the property
* Automatic synchronization between phones
* Must continue working when internet connectivity is temporarily unavailable

The architecture should allow future expansion to:

* Multiple properties
* More rooms
* Multiple staff
* OTA integrations
* Payment gateways
* Invoices
* GST configuration
* Advanced reporting
* Notifications

Do not implement these future features unless explicitly requested.

---

# 4. Important Generic Requirement

The application must NOT be tied to a particular property.

Never hard-code:

* Property name
* Property address
* Phone number
* Email
* Logo
* Number of rooms
* Room numbers
* Room types
* Room prices
* Tax percentages
* Currency
* Booking sources
* Payment methods

These must come from configuration/data.

For example:

```dart
PropertyConfig(
  name: ...,
  address: ...,
  phone: ...,
  email: ...,
  currency: ...,
)
```

Room information must come from Firestore/configuration rather than being hard-coded in widgets.

---

# 5. Architecture

Use a clean, maintainable architecture.

Recommended structure:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── rooms/
│   ├── bookings/
│   ├── guests/
│   ├── payments/
│   ├── expenses/
│   ├── reports/
│   └── settings/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│
└── firebase_options.dart
```

Use repository/service patterns.

Do not put business logic directly inside widgets.

Keep UI, state management, data access and business rules separated.

Prefer simple architecture over unnecessary abstraction.

Do not introduce additional backend infrastructure.

---

# 6. Backend

Use:

```text
Firebase Authentication
Cloud Firestore
```

Do NOT introduce:

* Spring Boot
* PostgreSQL
* Azure
* Custom REST backend
* WhatsApp-based synchronization
* Separate server
* Cloud Functions unless there is a clear unavoidable requirement

Firestore should provide synchronization and offline caching.

---

# 7. Authentication

Support at least:

```text
ADMIN
STAFF
```

Use Firebase Authentication.

Prefer email/password authentication for V1.

Avoid phone/SMS authentication because SMS introduces unnecessary cost and complexity.

Store user profile/role information in:

```text
users/{userId}
```

Example:

```json
{
  "displayName": "...",
  "email": "...",
  "role": "ADMIN",
  "propertyId": "...",
  "active": true,
  "createdAt": "...",
  "updatedAt": "..."
}
```

---

# 8. Property Configuration

Create configuration for:

```text
Property
Currency
Tax
Payment methods
Booking sources
Room types
Application settings
```

Example property configuration:

```text
properties/{propertyId}
```

Possible fields:

```text
name
address
phone
email
currency
timezone
taxEnabled
taxPercentage
checkInTime
checkOutTime
logoUrl
active
createdAt
updatedAt
```

The UI must load this information dynamically.

---

# 9. Firestore Data Model

Design the database so multi-property support is possible.

Recommended collections:

```text
properties/{propertyId}

users/{userId}

rooms/{roomId}

guests/{guestId}

bookings/{bookingId}

payments/{paymentId}

expenses/{expenseId}

settings/{settingId}
```

Every operational document should include appropriate audit fields:

```text
createdAt
updatedAt
createdBy
updatedBy
propertyId
```

Use Firestore server timestamps where appropriate.

Do not duplicate large amounts of data unnecessarily.

---

# 10. Rooms

Room statuses:

```text
AVAILABLE
BOOKED
CHECKED_IN
CHECKED_OUT
CLEANING
BLOCKED
```

Room configuration:

```text
roomId
propertyId
roomNumber
name
type
floor
maxOccupancy
basePrice
status
active
createdAt
updatedAt
```

Room types should be configurable.

Do not assume rooms are numbered 101, 102, etc.

---

# 11. Booking

Booking fields should support:

```text
bookingId
propertyId
guestId
roomId
guestName
guestPhone
adults
children
checkInDate
checkOutDate
pricePerNight
numberOfNights
subtotal
discount
tax
total
advancePaid
outstandingAmount
paymentStatus
bookingStatus
source
notes
createdAt
updatedAt
createdBy
updatedBy
```

Booking sources:

```text
WALK_IN
PHONE
WHATSAPP
WEBSITE
BOOKING_COM
MAKEMYTRIP
AGODA
OTHER
```

Make booking sources configurable in the future.

---

# 12. Booking Calculations

Implement calculations centrally, not inside widgets.

Basic calculation:

```text
numberOfNights =
    checkOutDate - checkInDate
```

Then:

```text
subtotal =
    pricePerNight * numberOfNights
```

Then:

```text
taxableAmount =
    subtotal - discount
```

Then:

```text
tax =
    taxableAmount * taxPercentage
```

Then:

```text
total =
    taxableAmount + tax
```

Then:

```text
outstanding =
    total - totalPayments
```

Protect against:

* Negative discounts
* Negative payments
* Check-out before check-in
* Zero/negative nights
* Payment greater than allowed outstanding unless explicitly permitted
* Invalid room availability

Create unit tests for these calculations.

---

# 13. Payment Management

Payments must be separate records.

Collection:

```text
payments/{paymentId}
```

Fields:

```text
paymentId
propertyId
bookingId
guestId
amount
paymentMode
reference
notes
paymentDate
createdAt
createdBy
```

Payment modes should be configurable, with typical defaults:

```text
CASH
UPI
CARD
BANK_TRANSFER
OTHER
```

Do not hard-code currency symbols in business logic.

---

# 14. Check-in / Check-out

Check-in should:

* Verify booking
* Verify room
* Change booking status
* Change room status
* Record timestamp
* Record user

Check-out should:

* Verify outstanding amount according to configured policy
* Record checkout timestamp
* Change booking status
* Change room status
* Optionally move room to CLEANING

Do not assume that every property has the same checkout policy.

Make such policies configurable where practical.

---

# 15. Guest Management

Guest records:

```text
guestId
propertyId
name
phone
email
address
idType
idNumber
notes
createdAt
updatedAt
```

Support guest history.

A guest should be able to have multiple bookings.

Do not duplicate guest information unnecessarily.

---

# 16. Dashboard

Dashboard should show configurable/current information such as:

```text
Total Rooms
Available
Occupied
Today's Check-ins
Today's Check-outs
Today's Revenue
Cash Collected
Online Payments
Outstanding
```

Also show:

```text
Today's bookings
Recent bookings
Room occupancy
```

Avoid excessive Firestore listeners.

Only query the data needed for the dashboard.

---

# 17. Expenses

Expense fields:

```text
expenseId
propertyId
date
amount
category
paymentMode
description
createdAt
createdBy
updatedAt
updatedBy
```

Example configurable categories:

```text
ELECTRICITY
WATER
SUPPLIES
MAINTENANCE
SALARY
CLEANING
OTHER
```

Do not assume these are the only categories.

---

# 18. Cash Management

Support:

```text
Opening Cash
Cash In
Cash Out
Expected Cash
Actual Cash
Variance
```

Cash transactions should be auditable.

Do not silently modify historical transactions.

---

# 19. Reports

V1 reports:

### Daily

```text
Bookings
Check-ins
Check-outs
Revenue
Cash
Online payments
Expenses
Outstanding
```

### Monthly

```text
Revenue
Expenses
Net
Occupancy
Payment-mode breakdown
Room-wise revenue
```

### Room-wise

```text
Room
Bookings
Nights occupied
Revenue
Occupancy
```

Reports should be based on Firestore queries and calculations.

Avoid downloading the entire database unnecessarily.

---

# 20. Navigation

Use a simple mobile-first navigation.

Primary navigation:

```text
Dashboard
Rooms
Bookings
More
```

Under More:

```text
Guests
Payments
Expenses
Reports
Settings
Users
```

Admin-only screens should be protected.

---

# 21. UI/UX

Use Material 3.

Design for Android phones first.

Prioritize:

* Large touch targets
* Simple forms
* Minimal typing
* Clear status indicators
* Fast booking creation
* Fast check-in/check-out
* Clear outstanding amount
* Easy payment entry
* Good empty states
* Confirmation dialogs for destructive actions

The app should be practical for a staff member using it while standing at a reception desk.

Avoid unnecessary animations.

Avoid overly complicated UI.

---

# 22. Offline Support

Firestore offline persistence is required.

The application should allow users to:

* View cached rooms
* View cached bookings
* Create bookings while temporarily offline
* Record payments while offline
* Perform normal operational tasks offline

When connectivity returns, Firestore should synchronize automatically.

Do not implement custom synchronization unless required.

Clearly handle potential stale data.

---

# 23. Two-phone Synchronization

Phone A and Phone B will use the same Firebase project.

Changes should synchronize through Firestore.

Example:

```text
Phone A
  ↓
Firestore
  ↓
Phone B
```

and:

```text
Phone B
  ↓
Firestore
  ↓
Phone A
```

Do not use:

* WhatsApp
* manual exports
* local file transfer
* custom sync servers

Design repositories so both devices use the same data source.

---

# 24. Concurrency

The expected usage is low concurrency.

Usually only one person creates/updates a booking at a time.

Therefore:

* Keep conflict handling simple
* Use Firestore timestamps
* Avoid unnecessarily complicated distributed locking
* Validate room availability before booking
* Use transactions where required to protect critical state changes

---

# 25. Security

Firestore security rules must enforce:

### Authentication

Unauthenticated users cannot access business data.

### Property isolation

Users should only access data belonging to their assigned property.

### Admin

Admin can:

* Manage property configuration
* Manage rooms
* Manage users
* Manage bookings
* Manage payments
* Manage expenses
* View reports

### Staff

Staff can:

* View rooms
* Create/update bookings
* Check guests in/out
* Record payments
* View operational information

Restrict configuration/user-management operations to admins.

Do not rely solely on UI hiding for security.

---

# 26. Code Quality

Follow these principles:

* Strong typing
* Null safety
* Small reusable widgets
* Meaningful names
* No magic numbers
* No hard-coded business data
* No secrets in source code
* No business logic in UI widgets
* Repository pattern for data access
* Unit tests for calculations
* Error handling
* Loading states
* Empty states
* Retry states
* Form validation

Run:

```powershell
flutter analyze
```

and

```powershell
flutter test
```

after significant changes.

The project should remain warning/error free.

---

# 27. Testing

Create tests for:

### Booking calculation

```text
1 night
Multiple nights
Discount
Tax
No tax
Zero discount
Invalid dates
```

### Payment calculation

```text
No payment
Partial payment
Full payment
Multiple payments
```

### Room availability

```text
Available room
Booked room
Checked-in room
Blocked room
```

### Date logic

```text
Same-day booking
Multi-day booking
Invalid checkout
```

---

# 28. Development Sequence

Implement in this order.

## Phase 1 — Project foundation

* Flutter project
* Material 3 theme
* App shell
* Navigation
* Folder structure
* Basic reusable widgets
* Git baseline

## Phase 2 — Configuration

* Property model
* Room model
* Settings model
* Configuration screens
* Generic property setup

## Phase 3 — Dashboard

* Dashboard cards
* Occupancy
* Today's check-ins
* Today's check-outs
* Revenue
* Outstanding

## Phase 4 — Rooms

* Room list
* Room status
* Room details
* Add/edit room
* Block/unblock room

## Phase 5 — Guests

* Guest list
* Guest search
* Guest details
* Guest history

## Phase 6 — Bookings

* Booking list
* Create booking
* Edit booking
* Booking details
* Availability validation
* Booking calculations

## Phase 7 — Payments

* Add payment
* Payment history
* Outstanding calculation
* Payment modes

## Phase 8 — Check-in / Check-out

* Check-in
* Check-out
* Room status transitions
* Audit information

## Phase 9 — Expenses/Cash

* Expenses
* Cash transactions
* Daily cash summary

## Phase 10 — Reports

* Daily
* Monthly
* Room-wise
* Payment-wise

## Phase 11 — Firebase

* Firebase configuration
* Authentication
* Firestore repositories
* Security rules
* Offline support

## Phase 12 — Multi-device testing

Test:

```text
Phone A → Firestore → Phone B
Phone B → Firestore → Phone A
```

Test offline → online synchronization.

## Phase 13 — Production hardening

* Error handling
* Security review
* Performance
* Validation
* Unit tests
* UI testing
* Release APK/AAB

---

# 29. Important Development Rule

Do not implement the entire application in one huge change.

Work feature-by-feature.

After every significant feature:

1. Run `flutter analyze`
2. Run relevant tests
3. Run the app
4. Verify the UI
5. Explain what changed
6. Wait for confirmation before moving to the next major feature

Never silently make architectural decisions that conflict with this specification.

If a requirement is ambiguous, identify the ambiguity and propose the smallest reasonable solution.

---

# 30. First Task

Start with **Phase 1 only**.

Create:

```text
lib/
├── main.dart
├── app/
├── core/
├── features/
│   ├── dashboard/
│   ├── rooms/
│   ├── bookings/
│   ├── guests/
│   ├── payments/
│   ├── expenses/
│   ├── reports/
│   └── settings/
└── data/
```

Implement:

* Material 3 theme
* Main application shell
* Bottom navigation
* Dashboard placeholder
* Rooms placeholder
* Bookings placeholder
* More/settings placeholder

Use clean reusable components.

Do NOT implement Firebase yet.

Do NOT create real property/room data yet.

Do NOT hard-code any real business information.

After Phase 1 is complete, run:

```powershell
flutter analyze
flutter test
flutter run -d chrome
```

Then report:

```text
1. Files created/changed
2. Architecture decisions
3. Tests run
4. Analyze result
5. How to run the application
6. What should be implemented next
```

Stop after Phase 1 and wait for approval.