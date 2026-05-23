import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/auth_repository.dart';

class PinState {
  final String pin;
  final bool busy;
  final String? error;
  const PinState({this.pin = '', this.busy = false, this.error});

  PinState copyWith({String? pin, bool? busy, String? error}) => PinState(
        pin: pin ?? this.pin,
        busy: busy ?? this.busy,
        error: error,
      );
}

class PinViewModel extends StateNotifier<PinState> {
  PinViewModel(this._auth) : super(const PinState());
  final AuthRepository _auth;

  void onDigit(String d) {
    if (state.pin.length >= 8) return;
    state = state.copyWith(pin: state.pin + d, error: null);
  }

  void backspace() {
    if (state.pin.isEmpty) return;
    state = state.copyWith(pin: state.pin.substring(0, state.pin.length - 1));
  }

  void clear() => state = state.copyWith(pin: '');

  Future<void> submit() async {
    if (state.pin.isEmpty) return;
    state = state.copyWith(busy: true);
    await _auth.signInWithPin(state.pin);
    state = state.copyWith(busy: false);
  }
}

final pinViewModelProvider =
    StateNotifierProvider.autoDispose<PinViewModel, PinState>((ref) {
  return PinViewModel(ref.watch(authStateProvider.notifier));
});
