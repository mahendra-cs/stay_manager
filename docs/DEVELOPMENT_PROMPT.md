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
* Local on-device storage (JSON document per device)
* WhatsApp for optional manual export to the administrator
* Android as the primary target
* Chrome/Web may be used during development
* VS Code is the primary IDE

Cloud project:

```text
none - the application runs with no cloud dependency
```

> **Amendment (2026-10-10).** The original specification required Firebase
> Authentication + Cloud Firestore. This was replaced by a local-first design so
> the application carries no cloud cost. See section 6 and the decision record
> in section 31. Firebase code is retained in the repository but is not wired in.

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

## 6.1 Current decision — no backend

The application has **no server and no cloud dependency**. Each device owns its
own data and persists it locally.

Storage:

```text
On-device JSON document (application documents directory)
  stay_manager_data.json
  ├── guests
  ├── bookings
  ├── payments
  ├── expenses
  └── cashSessions
```

Every write is flushed to disk immediately and re-read at startup, so closing
the app never loses data.

Optional reporting path (never required for core operation):

```text
Staff phone  →  CSV/JSON export  →  WhatsApp  →  Admin's computer
                                                         ↓
                                    admin_tool.html (browser, localStorage)
                                                         ↓
                                              Download → Google Drive (manual)
```

The admin tool is a single self-contained HTML page. It requires no server, no
account and no API key. Data stays in the browser until the admin downloads it.

## 6.2 Still forbidden

Do NOT introduce:

* Spring Boot
* PostgreSQL
* Azure
* Custom REST backend
* Separate server
* Cloud Functions
* Any service that bills the property owner

## 6.3 Export is one-way

The WhatsApp export is a **snapshot for records**, never a synchronization
channel:

* No file is ever read back into the application.
* The staff device remains the single source of truth.
* The admin must never hand-edit data that will be re-imported, because there
  is no merge step and no conflict resolution.

---

## 6.4 Superseded requirement (kept for reference)

The original specification required:

```text
Firebase Authentication
Cloud Firestore
```

and explicitly forbade:

* WhatsApp-based synchronization
* manual exports

That requirement was replaced on 2026-10-10. The Firestore repositories, security
rules and auth service are retained in the repository so the cloud path can be
restored by repointing `lib/main.dart`.

---

# 7. Authentication

Support at least:

```text
ADMIN
STAFF
```

## 7.1 Current decision — local sign-in

There is no identity provider. The application uses a local sign-in screen
(`InMemoryAuthService`) purely to distinguish roles within the device. It is a
usability feature, **not a security control**: anyone holding the unlocked device
has full access (see section 25.2).

Requirements:

* Email/password only. Never add SMS/phone authentication — SMS introduces
  cost and complexity for no benefit here.
* Sign-in must be skippable while no identity provider is configured, so local
  development is never blocked.
* Roles default to `STAFF` (least privilege).

## 7.2 Superseded — Firebase Authentication

The original requirement was to use Firebase Authentication with email/password,
storing profiles in `users/{userId}`. That implementation is retained in
`lib/data/repositories/firebase_auth_service.dart` and the `AppUser` model keeps
the same shape:

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

If a cloud identity provider is reintroduced, this document shape must be kept.

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

> **Note.** The `properties/{propertyId}` document reference is the original
> Firestore layout. Configuration is now held in memory and edited in-app, so
> this section describes *what* must be configurable, not where it is stored.

---

# 9. Data Model

Design the data so multi-property support remains possible.

## 9.1 Current storage

A single JSON document on the device, keyed by record id:

```text
stay_manager_data.json
├── property      (configuration)
├── rooms         { roomId: {...} }
├── guests        { guestId: {...} }
├── bookings      { bookingId: {...} }
├── payments      { paymentId: {...} }
├── expenses      { expenseId: {...} }
├── cashSessions  { sessionId: {...} }
└── settings      (configurable lists and policy)
```

Every operational record keeps the same audit fields:

```text
createdAt
updatedAt
createdBy
updatedBy
propertyId
```

Requirements:

* Each record carries its `id` inside the entry, because the flattened format
  has no document id to key off.
* Dates are stored as **ISO-8601 strings**. Raw `DateTime` values cannot be
  JSON-encoded and will silently break persistence — use `toJsonMap()`, never
  `toMap()`, when writing to disk or exporting.
* Do not duplicate large amounts of data unnecessarily.

## 9.2 Superseded — Firestore collections

The original multi-collection design is retained for the cloud path:

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

Firestore server timestamps no longer apply locally; device time is used, which
is acceptable because there is only one writer (see section 23).

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

**The device is always offline.** There is no network dependency, so every
operational task works with no connectivity at all — this is stronger than the
offline cache the original design required.

The application must allow users to:

* View rooms
* View bookings
* Create bookings
* Record payments
* Perform normal operational tasks

Data durability requirements:

* Writes must be flushed to disk immediately, not on exit.
* A crash or force-close must not lose a completed booking.
* A corrupt or unreadable data file must degrade to an empty state rather than
  preventing the app from starting.
* Writes must be serialized so two rapid saves cannot clobber each other.

> **Note.** Firestore offline persistence was the original mechanism. Local
> persistence replaces it, so no stale-data reconciliation is needed — there is
> no remote copy to disagree with.

---

# 23. Data Sharing and Reporting

There is **no automatic synchronization between devices.** This is a deliberate
change from the original two-phone synchronization requirement.

## Current model

```text
Staff phone (source of truth)
      │
      ├─ manual export (CSV / JSON)
      ▼
   WhatsApp
      │
      ▼
Admin's computer → admin_tool.html → browser localStorage
      │
      └─ download → Google Drive (manual upload by the admin)
```

Rules:

* The staff device owns the data. Exports are read-only snapshots.
* Exports are user-initiated; nothing is ever sent automatically.
* The admin tool is offline and requires no account, server or API key.
* Google Drive is used by manual upload, not by an integrated API.

## Accepted trade-offs

Because there is no live sync, the following are knowingly accepted:

* **Single-writer assumption.** One staff device is the source of truth. Two
  devices editing the same booking independently will not merge.
* **No live two-device view.** The admin sees data only after an export.
* **Manual reporting latency.** Reporting is as fresh as the last export.
* **Backup is the admin's responsibility.** If the staff device is lost, data is
  lost unless an export has been sent.

## Still forbidden

Do not introduce custom sync servers, background upload daemons, or any
billable service to close the gap. If live sync becomes necessary, revisit the
decision in section 31 rather than adding infrastructure silently.

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

## 25.1 Current model — local trust boundary

With no backend there is no server-side rule engine, so security is enforced in
three places instead:

| Layer | Control |
| ----- | ------- |
| Device | OS-level app sandbox; the data file is private to the app |
| Transport | Exports travel over WhatsApp's own end-to-end encryption |
| Application | Role-aware UI; destructive actions require confirmation |

Requirements:

* Unauthenticated use must not be possible once sign-in is enabled.
* Configuration and user-management screens are admin-only.
* Exported files must contain no credentials, tokens or keys.
* Destructive actions (delete booking, cancel, clear data) require explicit
  confirmation.

## 25.2 Known exposure

Be explicit about what this design does **not** protect against:

* A lost or stolen, unlocked device exposes all local data.
* An exported file is only as private as the WhatsApp chat it is sent to.
* Anyone with the file can read it; exports are unencrypted.

If the property later needs stronger guarantees, that is the trigger to revisit
the decision in section 31.

## 25.3 Roles (unchanged)

### Admin can

* Manage property configuration
* Manage rooms
* Manage users
* Manage bookings
* Manage payments
* Manage expenses
* View reports
* Trigger exports

### Staff can

* View rooms
* Create/update bookings
* Check guests in/out
* Record payments
* View operational information
* Trigger exports

Restrict configuration/user-management operations to admins.

Do not rely solely on UI hiding for authorization intent, but note that without a
backend the rules are no longer independently enforceable — see 25.2.

## 25.4 Superseded — Firestore rules

The original requirement to enforce these rules through Firestore security rules
is retained in `firestore.rules` for the cloud path and is not active while the
application runs locally.

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

## Phase 11 — Firebase / Local Persistence

*Superseded. Replaced by local persistence (done). The Firestore repositories,
security rules and auth service remain in the repository, unused.*

Original scope, if it is ever restored:

* Firebase configuration
* Authentication
* Firestore repositories
* Security rules
* Offline support

## Phase 11′ — Local Persistence (replacement, done)

* JSON document storage on device
* Immediate write-through on every save
* Serialized writes, corrupt-file recovery
* Date serialization via `toJsonMap()`

## Phase 11″ — Data Export (replacement, done)

* CSV/JSON export of bookings, payments and guests
* Share via the system share sheet (WhatsApp in practice)
* Read-only snapshot; nothing is imported back
* `admin_tool.html` for import, totals and CSV/JSON download on a computer

## Phase 12 — Multi-device Testing

*Superseded by section 23 — there is no automatic sync to test.*

Original scope, retained for reference:

Test:

```text
Phone A → Firestore → Phone B
Phone B → Firestore → Phone A
```

Test offline → online synchronization.

Replacement scope for the local design:

* Create data on the staff device, close the app, reopen, confirm it persisted.
* Export, import into `admin_tool.html`, confirm totals reconcile.
* Force-close mid-operation and confirm no completed booking is lost.
* Confirm the app starts with a corrupted data file.

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

---

# 31. Decision Record

Amendments to this specification, in order. Every architectural change is
recorded here with its rationale and trade-offs, so that future work does not
silently reverse a decision without confronting the consequences.

---

## ADR-001 — Replace Firebase with local-first storage and manual export

**Date:** 2026-10-10
**Status:** Accepted
**Sections affected:** 2, 6, 7, 9, 22, 23, 25, 28

### Context

The original specification mandated Firebase Authentication and Cloud Firestore,
and explicitly forbade WhatsApp-based synchronization and manual exports.

The owner asked to remove the cloud dependency entirely so the application can
never incur a cloud bill, proposing:

```text
Staff phone  →  export  →  WhatsApp  →  Admin's computer
                                                  ↓
                                     download / upload to Google Drive
```

The conflict with the specification was raised before implementation began, and
the owner accepted it and directed the change.

### Decision

The application stores data locally on the staff device and exports
read-only snapshots over WhatsApp for the administrator. No cloud service is
used or billed.

### Rationale as given

Absolute certainty of zero cloud cost.

### Counter-argument recorded for future reference

Firebase's free (Spark) tier allows 50,000 reads and 20,000 writes per day with
no payment method required. For a property with ~9 rooms and a handful of daily
bookings, usage would be a tiny fraction of that allowance. The Firestore design
would very likely have remained free in practice while providing real-time sync,
offline-first behaviour and automatic conflict handling — none of which the
manual export provides.

This is recorded so the trade-off is understood rather than assumed.

### Consequences

Gained:

* Zero cloud cost, guaranteed.
* No account, API key or service configuration.
* Works with no connectivity, by construction.
* Data stays on the property's own device.

Lost:

* No live synchronization between devices (section 23).
* Single-writer only; concurrent edits cannot merge.
* The admin's view is only as fresh as the last export.
* Device loss means data loss unless an export was sent.
* Local sign-in is a usability feature, not a security control (section 25.2).
* Exported files are unencrypted and as private as the chat carrying them.

### Reversal path

The cloud implementation was deliberately **not deleted**:

* `lib/data/repositories/firestore_config_repository.dart`
* `lib/data/repositories/firestore_operations_repository.dart`
* `lib/data/repositories/firebase_auth_service.dart`
* `firestore.rules`, `firebase.json`, `.firebaserc`

Restoring the cloud path means repointing `lib/main.dart` at those repositories
and running `flutterfire configure`. No screen code needs to change, because
both paths implement the same repository interfaces.

### Triggers that should reopen this decision

* Staff or admin requests live data on two devices simultaneously.
* Data loss from a lost or damaged device causes real harm.
* The manual export routine is missed often enough to affect reporting.
* The property later requires enforceable role-based access control.

---

## ADR-002 — Store dates as ISO-8601 strings

**Date:** 2026-10-10
**Sections affected:** 9

### Context

Models expose two serializations: `toMap()` returns raw `DateTime` values
because Firestore stores them as timestamps, while `toJsonMap()` returns
ISO-8601 strings.

### Problem found

When local persistence was introduced, `toMap()` was used and `jsonEncode`
threw `Converting object to an encodable object failed: Instance of 'DateTime'`
on **every save**. Because the failure was swallowed to protect the UI, the app
appeared to work while silently discarding all data.

### Decision

* `toMap()` is for Firestore only and may contain `DateTime`.
* `toJsonMap()` is for disk and export and must contain only encodable values.
* Anything writing JSON **must** use `toJsonMap()`.
* A regression test covers a save/reload round trip.

### Rule

Never call `toMap()` when the result is passed to `jsonEncode`.