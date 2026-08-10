import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository.instance,
);

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;

  const AuthState({
    required this.status,
    this.user,
  });

  const AuthState.checking()
      : status = AuthStatus.checking,
        user = null;

  const AuthState.authenticated({
    this.user,
  }) : status = AuthStatus.authenticated;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null;
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
      final hasSession =
          await _repository.hasStoredSession();

      if (!hasSession) {
        state = const AuthState.unauthenticated();
        return;
      }

      final response =
          await _repository.getCurrentUser();

      if (response.success &&
          response.data != null) {
        state = AuthState.authenticated(
          user: response.data,
        );
        return;
      }

      // --------------------------------------------------------
      // Access token may have expired.
      // Try refresh token.
      // --------------------------------------------------------

      final refreshResponse =
          await _repository.refreshToken();

      if (!refreshResponse.success) {
        await _repository.logout();

        state = const AuthState.unauthenticated();
        return;
      }

      // --------------------------------------------------------
      // Get current user again using new access token.
      // --------------------------------------------------------

      final refreshedUser =
          await _repository.getCurrentUser();

      if (refreshedUser.success &&
          refreshedUser.data != null) {
        state = AuthState.authenticated(
          user: refreshedUser.data,
        );
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

  Future<bool> login({
    required String email,
    required String password,
  }) async {
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

      // --------------------------------------------------------
      // Load the logged-in user's profile.
      // --------------------------------------------------------

      final userResponse =
          await _repository.getCurrentUser();

      if (userResponse.success &&
          userResponse.data != null) {
        state = AuthState.authenticated(
          user: userResponse.data,
        );

        return true;
      }

      await _repository.logout();

      state = const AuthState.unauthenticated();
      return false;
    } catch (_) {
      state = const AuthState.unauthenticated();
      return false;
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
        // Registration does NOT automatically log the user in.
        //
        // The planned flow is:
        //
        // Signup → Login → Home
        //

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

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
