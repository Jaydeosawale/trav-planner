import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository.instance,
);

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;

  const AuthState({required this.status, this.user});

  const AuthState.checking() : status = AuthStatus.checking, user = null;

  const AuthState.authenticated({this.user})
    : status = AuthStatus.authenticated;

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      user = null;

  // ========================================================
  // Role helpers
  // ========================================================

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  bool get isAdmin => isAuthenticated && user!.isAdmin;

  bool get isUser => isAuthenticated && user!.isUser;
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);

    return const AuthState.checking();
  }

  // ==========================================================
  // Check Session
  // ==========================================================

  Future<void> checkSession() async {
    state = const AuthState.checking();

    try {
      final hasSession = await _repository.hasStoredSession();

      if (!hasSession) {
        state = const AuthState.unauthenticated();
        return;
      }

      // ------------------------------------------------------
      // Try existing access token
      // ------------------------------------------------------

      final response = await _repository.getCurrentUser();

      if (response.success && response.data != null) {
        state = AuthState.authenticated(user: response.data);
        return;
      }

      // ------------------------------------------------------
      // Access token expired.
      // Try refresh token.
      // ------------------------------------------------------

      final refreshResponse = await _repository.refreshToken();

      if (!refreshResponse.success) {
        await _repository.logout();

        state = const AuthState.unauthenticated();
        return;
      }

      // ------------------------------------------------------
      // Get current user using new access token.
      // ------------------------------------------------------

      final refreshedUser = await _repository.getCurrentUser();

      if (refreshedUser.success && refreshedUser.data != null) {
        state = AuthState.authenticated(user: refreshedUser.data);
      } else {
        await _repository.logout();

        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      await _repository.logout();

      state = const AuthState.unauthenticated();
    }
  }

  // ==========================================================
  // Login
  // ==========================================================

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState.checking();

    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );

      if (!response.success) {
        state = const AuthState.unauthenticated();
        return false;
      }

      // ------------------------------------------------------
      // Load logged-in user's profile.
      // ------------------------------------------------------

      final userResponse = await _repository.getCurrentUser();

      if (userResponse.success && userResponse.data != null) {
        state = AuthState.authenticated(user: userResponse.data);

        return true;
      }

      // ------------------------------------------------------
      // Login succeeded but profile failed.
      // ------------------------------------------------------

      await _repository.logout();

      state = const AuthState.unauthenticated();

      return false;
    } catch (_) {
      state = const AuthState.unauthenticated();

      return false;
    }
  }

  // ==========================================================
  // Get Admin Profile
  // ==========================================================

  Future<UserModel?> getCurrentAdmin() async {
    try {
      final response = await _repository.getCurrentAdmin();

      if (response.success && response.data != null) {
        return response.data;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // Register
  // ==========================================================

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthState.checking();

    try {
      final response = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.success) {
        // Registration does not automatically
        // authenticate the user.
        //
        // Signup → Login → Home/Admin Dashboard

        state = const AuthState.unauthenticated();

        return true;
      }

      state = const AuthState.unauthenticated();

      return false;
    } catch (_) {
      state = const AuthState.unauthenticated();

      return false;
    }
  }

  // ==========================================================
  // Logout
  // ==========================================================

  Future<void> logout() async {
    await _repository.logout();

    state = const AuthState.unauthenticated();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
