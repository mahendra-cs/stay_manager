import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../data/models/app_user.dart';
import 'auth_controller.dart';
import 'auth_scope.dart';
import 'login_widgets.dart';

/// Email/password sign-in and registration (spec 7).
///
/// Email/password is used deliberately: the spec avoids SMS/phone auth to
/// keep cost and complexity down.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.propertyName = '', this.allowSignUp = true});

  /// Shown as context so the user knows what they are signing in to.
  final String propertyName;

  /// False when registration should be hidden.
  final bool allowSignUp;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _displayName;

  bool _isRegistering = false;
  bool _obscurePassword = true;
  UserRole _role = UserRole.staff;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
    _displayName = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = AuthScope.of(context);

    if (_isRegistering) {
      await auth.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _displayName.text,
        propertyId: '',
        role: _role,
      );
    } else {
      await auth.signIn(email: _email.text, password: _password.text);
    }
    // On success the surrounding gate rebuilds automatically.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthScope.of(context);
    final canRegister = widget.allowSignUp && !_isRegistering;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.propertyName.isEmpty
                          ? 'Property Manager'
                          : widget.propertyName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegistering
                          ? 'Create an account to get started'
                          : 'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    ..._fields(auth, canRegister),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _fields(AuthController auth, bool canRegister) => [
        if (_isRegistering) ...[
          TextFormField(
            controller: _displayName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
                Validators.required(value, fieldName: 'Name'),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email *',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            final required = Validators.required(value, fieldName: 'Email');
            if (required != null) return required;
            return Validators.email(value);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _password,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            final required = Validators.required(value, fieldName: 'Password');
            if (required != null) return required;
            if ((value ?? '').trim().length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        if (_isRegistering) ...[
          const SizedBox(height: 16),
          RoleSelector(
            role: _role,
            onChanged: (role) => setState(() => _role = role),
          ),
        ],
        if (auth.error != null) ...[
          const SizedBox(height: 16),
          ErrorBanner(message: auth.error!),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: auth.isBusy ? null : _submit,
          icon: auth.isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isRegistering ? Icons.person_add_alt : Icons.login),
          label: Text(_isRegistering ? 'Create account' : 'Sign in'),
        ),
        if (canRegister) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              auth.clearError();
              setState(() => _isRegistering = !_isRegistering);
            },
            child: Text(
              _isRegistering
                  ? 'Already have an account? Sign in'
                  : 'First time here? Create an account',
            ),
          ),
        ],
      ];
}
