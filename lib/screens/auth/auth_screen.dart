import 'package:fluffy_link/core/page_scaffold.dart';
import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthScope.of(context);
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_tabController.index == 0) {
        await authService.signIn(email: email, password: password);
      } else {
        await authService.signUp(email: email, password: password);
      }

      if (mounted) {
        final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
        context.go(
          redirect != null && redirect.isNotEmpty
              ? Uri.decodeComponent(redirect)
              : '/dashboard',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _messageForAuthError(e);
        });
      }
    }
  }

  String _messageForAuthError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('invalid login credentials')) {
      return 'That email and password combination was not recognized.';
    }
    if (text.contains('already registered') || text.contains('already exists')) {
      return 'An account already exists for this email. Sign in instead.';
    }
    if (text.contains('password')) {
      return 'Use a stronger password with at least 8 characters.';
    }
    return 'We could not complete authentication. Check your details and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      currentRoute: '/auth',
      scrollable: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.glowShadow(opacity: 0.10, blur: 22),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.glowShadow(opacity: 0.12, blur: 14),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Welcome to Perma.link',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to upload, manage, and share permanent files.',
              style: TextStyle(color: AppTheme.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: AppTheme.primary,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.muted,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Sign Up'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tab content
            SizedBox(
              height: 42,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent('Use your email and password to continue.'),
                  _buildTabContent('Create an account before uploading files.'),
                ],
              ),
            ),

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'your@email.com',
                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your email';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              obscureText: !_showPassword,
              enableSuggestions: false,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }
                if (_tabController.index == 1 && value.length < 8) {
                  return 'Use at least 8 characters';
                }
                return null;
              },
            ),

            // Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_tabController.index == 0 ? 'Sign In' : 'Sign Up'),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel
            TextButton(
              onPressed: () => context.go('/'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'Back to home',
                style: TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        description,
        style: TextStyle(color: AppTheme.muted, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}


