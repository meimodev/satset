import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dummy_data.dart';
import '../models/user.dart';

class AuthState {
  final bool isAuthenticated;
  final AppUser? user;
  const AuthState({this.isAuthenticated = false, this.user});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void signIn() {
    state = const AuthState(isAuthenticated: true, user: DummyData.maya);
  }

  void signOut() {
    state = const AuthState();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
