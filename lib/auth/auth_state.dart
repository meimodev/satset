import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/dummy_data.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
  });

  AuthState copyWith({bool? isAuthenticated, User? user, bool clearUser = false}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  bool login(String username, String password) {
    final user = DummyData.users.cast<User?>().firstWhere(
      (u) => u!.username == username,
      orElse: () => null,
    );

    if (user == null) {
      state = state.copyWith(isAuthenticated: false);
      return false;
    }

    // Dummy auth — any password works for now
    state = state.copyWith(isAuthenticated: true, user: user);
    return true;
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false, clearUser: true);
  }

  void switchUser(User user) {
    state = state.copyWith(user: user);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
