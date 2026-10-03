import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models/app_settings.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_service.dart';
import '../data/repositories/in_memory_auth_service.dart';
import '../data/repositories/in_memory_config_repository.dart';
import '../data/repositories/in_memory_operations_repository.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_scope.dart';
import '../features/auth/login_page.dart';
import '../features/bookings/booking_form_page.dart';
import '../features/bookings/bookings_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/operations/operations_controller.dart';
import '../features/operations/operations_scope.dart';
import '../features/rooms/rooms_page.dart';
import '../features/settings/config_controller.dart';
import '../features/settings/config_scope.dart';
import '../features/settings/settings_page.dart';
import 'theme/app_theme.dart';

/// Application root.
///
/// Wraps the app in [ConfigScope] *and* [OperationsScope] so every screen can
/// read configuration (property, rooms, settings) and operational data
/// (guests, bookings, payments, expenses).
///
/// When no controllers are supplied (for example in widget tests) seeded,
/// in-memory controllers are created automatically.
class StayManagerApp extends StatefulWidget {
  const StayManagerApp({
    super.key,
    this.configController,
    this.operationsController,
    this.authController,
    this.requireSignIn = false,
  });

  final ConfigController? configController;
  final OperationsController? operationsController;

  /// When null and [requireSignIn] is true, a local offline auth service is
  /// used so the app is usable without Firebase.
  final AuthController? authController;

  /// Forces the login screen. Left false while Firebase is not configured so
  /// the app remains usable during development.
  final bool requireSignIn;

  @override
  State<StayManagerApp> createState() => _StayManagerAppState();
}

class _StayManagerAppState extends State<StayManagerApp> {
  late final ConfigController _config =
      widget.configController ?? ConfigController(InMemoryConfigRepository.seeded());

  late final OperationsController _operations =
      widget.operationsController ??
      OperationsController(
        InMemoryOperationsRepository(),
        // Rooms live in configuration, so the operations layer drives room
        // status through this narrow seam rather than holding room state.
        roomStatusWriter: _config,
        settings: _config.isLoading
            ? const AppSettings(id: '', propertyId: '')
            : _config.settings,
      );

  late final AuthController _auth = widget.authController ??
      AuthController(
        widget.requireSignIn
            ? InMemoryAuthService()
            : _AlwaysSignedInService(),
      );

  @override
  void initState() {
    super.initState();
    if (_config.isLoading) {
      unawaited(_config.load().then((_) {
        if (!mounted) return;
        _operations.updateSettings(_config.settings);
      }));
    }
    if (_operations.isLoading) {
      unawaited(_operations.load());
    }
  }

  @override
  void dispose() {
    if (widget.authController == null) _auth.dispose();
    if (widget.operationsController == null) _operations.dispose();
    if (widget.configController == null) _config.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OperationsScope(
      controller: _operations,
      child: ConfigScope(
        controller: _config,
        child: AuthScope(
          controller: _auth,
          child: MaterialApp(
            title: 'Property Manager',
            theme: AppTheme.light,
            home: widget.requireSignIn
                ? const AuthGate(child: AppShell())
                : const AppShell(),
          ),
        ),
      ),
    );
  }
}

/// Shows the login screen until a user is signed in.
///
/// Kept separate from `MaterialApp` so the screen can be swapped without
/// rebuilding the navigator.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final config = ConfigScope.of(context);

    if (!auth.isSignedIn) {
      return LoginPage(
        propertyName: config.isLoading ? '' : config.property.name,
      );
    }
    return child;
  }
}

/// Auth service used before Firebase is configured: the app behaves as if an
/// admin were signed in, so local development is never blocked by a missing
/// project. Swap for `FirebaseAuthService` as soon as Firebase is connected.
class _AlwaysSignedInService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  late final AppUser _user = AppUser(
    id: 'local-admin',
    displayName: 'Local Admin',
    email: 'local@localhost',
    role: UserRole.admin,
    propertyId: 'property-default',
  );

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async =>
      _user;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String propertyId,
    required UserRole role,
  }) async =>
      _user;

  @override
  Future<void> signOut() async {}
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Index of the Bookings destination, used to show its floating action.
  static const int bookingsTabIndex = 2;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    _NavigationDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _NavigationDestination(
      label: 'Rooms',
      icon: Icons.meeting_room_outlined,
      selectedIcon: Icons.meeting_room,
    ),
    _NavigationDestination(
      label: 'Bookings',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    _NavigationDestination(
      label: 'More',
      icon: Icons.more_horiz,
      selectedIcon: Icons.more_horiz,
    ),
  ];

  static const _pages = [
    DashboardPage(),
    RoomsPage(),
    BookingsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final config = ConfigScope.of(context);

    if (config.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final destination = _destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(destination.label)),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: _selectedIndex == AppShell.bookingsTabIndex
          ? FloatingActionButton.extended(
              onPressed: _newBooking,
              icon: const Icon(Icons.add),
              label: const Text('New booking'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }

  /// Primary action of the app: reserve a room and record guest details
  /// (spec §21 — fast booking creation).
  Future<void> _newBooking() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const BookingFormPage()),
    );
  }
}

class _NavigationDestination {
  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
