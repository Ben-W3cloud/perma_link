import 'package:fluffy_link/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  AuthService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  User? _currentUser;
  bool _initialized = false;

  User? get currentUser => _currentUser;
  bool get isInitialized => _initialized;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _currentUser = _supabase.auth.currentUser;
      _supabase.auth.onAuthStateChange.listen((AuthState authState) {
        final newUser = authState.session?.user;
        if (newUser?.id != _currentUser?.id) {
          _currentUser = newUser;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('AuthService.initialize skipped: $e');
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _currentUser = response.user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: '${AppConstants.appDomain}/dashboard',
      );
      _currentUser = response.user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}

class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService authService,
    required super.child,
  }) : super(notifier: authService);

  static AuthService of(BuildContext context) {
    final authScope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    if (authScope == null) {
      throw FlutterError('AuthScope not found in context');
    }
    return authScope.notifier!;
  }
}
