import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/domain/models/user.dart';

class AuthState {
  final bool isAuthenticated;
  final AppUser? user;
  const AuthState({this.isAuthenticated = false, this.user});
}

class AuthRepository extends StateNotifier<AuthState> {
  AuthRepository(this._seed) : super(const AuthState());

  final DummyDataService _seed;

  void signIn() {
    state = AuthState(isAuthenticated: true, user: _seed.defaultSignInUser);
  }

  void signOut() {
    state = const AuthState();
  }
}

final authStateProvider = StateNotifierProvider<AuthRepository, AuthState>(
    (ref) => AuthRepository(ref.watch(dummyDataServiceProvider)));
