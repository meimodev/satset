import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/io_client.dart' as http_io;
import 'package:uuid/uuid.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/pair_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/mdns_browser_service.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/secure_storage_service.dart';
import 'package:satset/domain/models/admission.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/ui/features/onboarding/view_models/mode_select_view_model.dart';

enum SignInMode { admin, staff }

/// Where the staff half of the sign-in screen is. One enum replaces the three
/// booleans this screen used to carry — a widget-local `_serverEditing`, the
/// view-model's `selectedServer.paired`, and a widget-local `_sheetOpen` that
/// stayed `true` forever if the sheet ever threw, after which the PIN pad could
/// not be reopened at all.
///
/// **A stage a user can enter must be one they can re-enter.** The enum killed
/// the throw trap and reintroduced the same shape a level down: dismissing the
/// pad dropped to [pickingServer], where tapping the already-selected paired
/// server changed nothing, and the pad opens on a stage *edge* — so the only
/// exits left were resetting the pairing or killing the app. Two things hold
/// it now: [selectServer] promotes a paired pick to [connected], and
/// [dismissPinPad] — not the screen — decides where a closed pad lands.
enum StaffStage {
  /// Choosing a server: the paired one, anything mDNS has found, or a typed
  /// address. Also where "ganti server" and a failed pairing land.
  ///
  /// Entered deliberately, and always leavable: tapping a paired row from here
  /// promotes to [connected], which is what re-opens the pad.
  pickingServer,

  /// A paired server is selected and reachable; the card is showing.
  connected,

  /// The PIN pad is up.
  enteringPin,
}

class PairedServerInfo {
  final String host;
  final int port;
  final String fingerprint;
  final String label;

  /// True when the device has previously paired with this server (token in
  /// secure storage); false for entries surfaced only by live mDNS discovery.
  final bool paired;

  /// App version reported in mDNS TXT, informational only.
  final String? version;

  const PairedServerInfo({
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.label,
    this.paired = true,
    this.version,
  });

  String get key => '$host:$port';
  String get ipLine => '$host:$port';
}

class PinState {
  final SignInMode mode;
  final bool adminBusy;

  /// The last admission attempt's outcome, or null before the first one. The
  /// screen switches on this — it is not an error string, because eleven of the
  /// fifteen outcomes are not errors and four of them say nothing at all.
  final AdmissionOutcome? admission;
  final List<PairedServerInfo> servers;
  final String? selectedServerKey;
  final bool pairingBusy;
  final String? pairingError;
  final StaffStage stage;

  const PinState({
    this.mode = SignInMode.staff,
    this.adminBusy = false,
    this.admission,
    this.servers = const [],
    this.selectedServerKey,
    this.pairingBusy = false,
    this.pairingError,
    this.stage = StaffStage.pickingServer,
  });

  PairedServerInfo? get selectedServer {
    if (selectedServerKey == null) return null;
    for (final s in servers) {
      if (s.key == selectedServerKey) return s;
    }
    return null;
  }

  PinState copyWith({
    SignInMode? mode,
    bool? adminBusy,
    Object? admission = _unset,
    List<PairedServerInfo>? servers,
    Object? selectedServerKey = _unset,
    bool? pairingBusy,
    Object? pairingError = _unset,
    StaffStage? stage,
  }) => PinState(
    mode: mode ?? this.mode,
    adminBusy: adminBusy ?? this.adminBusy,
    admission: admission == _unset
        ? this.admission
        : admission as AdmissionOutcome?,
    stage: stage ?? this.stage,
    servers: servers ?? this.servers,
    selectedServerKey: selectedServerKey == _unset
        ? this.selectedServerKey
        : selectedServerKey as String?,
    pairingBusy: pairingBusy ?? this.pairingBusy,
    pairingError: pairingError == _unset
        ? this.pairingError
        : pairingError as String?,
  );
}

const Object _unset = Object();

/// Controller behind the unified sign-in screen. Owns:
///   - mode switch (Admin / Staff)
///   - staff PIN entry + submit
///   - admin credential submit (dummy: bypasses email/password)
///   - paired-server discovery and selection
///   - live mDNS server discovery + LAN-trusted auto-claim
///
/// The widget renders state and routes user intent through these actions —
/// it does not own auth, pairing or mode logic.
class PinViewModel extends StateNotifier<PinState> {
  PinViewModel(this._ref, PrefsService prefs, this._storage, this._mdns)
    : _prefs = prefs,
      super(
        PinState(
          mode: prefs.appMode() == AppMode.server
              ? SignInMode.admin
              : SignInMode.staff,
        ),
      ) {
    refreshPairedServers();
    _startDiscovery();
  }

  final Ref _ref;
  final PrefsService _prefs;
  final SecureStorageService _storage;
  final MdnsBrowserService _mdns;

  PairedServerInfo? _pairedFromPrefs;
  List<DiscoveredServer> _discovered = const [];
  StreamSubscription<List<DiscoveredServer>>? _mdnsSub;

  AuthRepository get _auth => _ref.read(authStateProvider.notifier);

  void _startDiscovery() {
    // Fire-and-forget: PinViewModel must not block on mDNS readiness.
    unawaited(_mdns.start());
    _mdnsSub = _mdns.servers.listen(_onDiscovered);
    // Seed with anything already in the cache (subscribers join late).
    _onDiscovered(_mdns.current);
  }

  void _onDiscovered(List<DiscoveredServer> list) {
    _discovered = list;
    _rebuildServers();
  }

  Future<void> refreshPairedServers() async {
    final host = _prefs.pairedHost();
    final port = _prefs.pairedPort();
    final fp = await _storage.readServerFingerprint();
    if (host == null ||
        host.isEmpty ||
        port == null ||
        fp == null ||
        fp.isEmpty) {
      _pairedFromPrefs = null;
    } else {
      _pairedFromPrefs = PairedServerInfo(
        host: host,
        port: port,
        fingerprint: fp,
        label: host,
      );
    }
    _rebuildServers();
  }

  void _rebuildServers() {
    // Captured before the rebuild so the stage can be promoted on the *edge* —
    // the moment an unpaired selection becomes a paired one. Promoting on the
    // level instead would drag the user back to the connected card every mDNS
    // tick after they asked to change server.
    final hadPaired = state.selectedServer?.paired ?? false;
    final byKey = <String, PairedServerInfo>{};
    var pairedLocal = _pairedFromPrefs;

    // DHCP can move the paired server to a new IP. Identity is the TLS
    // fingerprint, not host:port — so if mDNS surfaces our paired fingerprint
    // at a different address, re-home the pairing to that address (persist the
    // new host/port) instead of leaving the selection pinned to a dead IP that
    // every request would time out against.
    final cur = pairedLocal;
    if (cur != null) {
      for (final d in _discovered) {
        final sameFp =
            d.fingerprint.toLowerCase() == cur.fingerprint.toLowerCase();
        final moved = d.host != cur.host || d.port != cur.port;
        if (sameFp && moved) {
          SatLog.vm(
            'PinVM: paired server re-homed ${cur.host}:${cur.port}'
            ' → ${d.host}:${d.port} (fingerprint match)',
          );
          unawaited(_prefs.setPairedHost(d.host));
          unawaited(_prefs.setPairedPort(d.port));
          pairedLocal = PairedServerInfo(
            host: d.host,
            port: d.port,
            fingerprint: cur.fingerprint,
            label: cur.label,
            paired: true,
          );
          _pairedFromPrefs = pairedLocal;
          // The stale selectedServerKey (old address) is no longer in byKey, so
          // the selection-fallback tail re-defaults to this re-homed entry.
          break;
        }
      }
    }

    final paired = pairedLocal;
    if (paired != null) {
      byKey[paired.key] = paired;
    }
    for (final d in _discovered) {
      final key = '${d.host}:${d.port}';
      final isPaired =
          paired != null && paired.host == d.host && paired.port == d.port;

      String fp = d.fingerprint;
      if (isPaired && paired.fingerprint != d.fingerprint) {
        SatLog.vm(
          'PinVM: Stale fingerprint detected for paired server at ${d.host}:${d.port}. '
          'Updating stored fingerprint from ${paired.fingerprint} to ${d.fingerprint}',
        );
        unawaited(_storage.writeServerFingerprint(d.fingerprint));
        _pairedFromPrefs = PairedServerInfo(
          host: paired.host,
          port: paired.port,
          fingerprint: d.fingerprint,
          label: paired.label,
          paired: true,
        );
      } else if (isPaired) {
        fp = paired.fingerprint;
      }

      byKey[key] = PairedServerInfo(
        host: d.host,
        port: d.port,
        fingerprint: fp,
        label: d.label,
        paired: isPaired,
        version: d.version,
      );
    }
    final list = byKey.values.toList()
      // Paired first, then by label for stability.
      ..sort((a, b) {
        if (a.paired != b.paired) return a.paired ? -1 : 1;
        return a.label.compareTo(b.label);
      });

    // Keep current selection if still present; else default to the first
    // paired entry (discovered-only entries require explicit auto-claim).
    String? sel = state.selectedServerKey;
    if (sel != null && !byKey.containsKey(sel)) sel = null;
    if (sel == null) {
      for (final s in list) {
        if (s.paired) {
          sel = s.key;
          break;
        }
      }
    }

    final nowPaired =
        sel != null && (byKey[sel]?.paired ?? false);
    state = state.copyWith(
      servers: list,
      selectedServerKey: sel,
      stage: !hadPaired && nowPaired ? StaffStage.connected : null,
    );

    // Don't override the loopback ApiConfig that Admin/Server mode publishes.
    if (state.mode != SignInMode.admin && sel != null) {
      final current = list.firstWhere(
        (s) => s.key == sel,
        orElse: () => list.first,
      );
      if (current.paired) _publishApiConfig(current);
    }
  }

  /// The toggle is the truth, and `AppMode` follows it. The persisted mode is a
  /// memory of what this device was last time; the person holding it knows what
  /// it is now, and must outrank that memory. See ADR-0098.
  void setMode(SignInMode m) {
    if (state.mode == m) return;
    SatLog.vm('PinVM setMode ${m.name}');
    state = state.copyWith(mode: m, admission: null);
    if (m == SignInMode.staff) {
      // verifyPin() re-persists mode and is the authoritative gate.
      _persistMode(AppMode.client).catchError((Object e) {
        SatLog.vm('PinVM setMode persist fail $e');
      });
      // Re-enter the rebuild so the selected paired server publishes its
      // ApiConfig. `_publishApiConfig` refuses to run in Admin mode — it would
      // clobber the loopback config — so the flip has to bring us back through
      // it. Without this, a staff member on a device that once hosted the venue
      // reached a PIN pad with no server behind it, and the pad answered
      // "server belum siap" until an unrelated mDNS tick happened to fire.
      _rebuildServers();
    }
    // Admin server boot is deferred to submitAdmin() so a failure can be
    // surfaced as an outcome and block sign-in.
  }

  /// Move the staff half between its three stages. The screen never writes
  /// stage state of its own — a second copy of "where are we" is what made the
  /// PIN pad unopenable when the sheet threw on the way up.
  void setStage(StaffStage s) {
    if (state.stage == s) return;
    SatLog.vm('PinVM setStage ${s.name}');
    state = state.copyWith(stage: s);
  }

  /// Forget this device's pairing and go back to discovery.
  ///
  /// The only way out of a pairing that cannot work — a server re-homed to a
  /// dead address, a fingerprint that will never match again, a wedge nobody
  /// has diagnosed yet. Before this, the exit was to uninstall the app.
  Future<void> resetPairing() async {
    SatLog.vm('PinVM resetPairing');
    await _storage.clearSession();
    await _storage.writeServerFingerprint(null);
    await _prefs.setPairedHost(null);
    await _prefs.setPairedPort(null);
    _ref.read(apiConfigProvider.notifier).state = null;
    _pairedFromPrefs = null;
    state = state.copyWith(
      selectedServerKey: null,
      pairingError: null,
      stage: StaffStage.pickingServer,
    );
    await refreshPairedServers();
  }

  Future<void> _persistMode(AppMode m) async {
    if (_prefs.appMode() == m) return;
    await _prefs.setAppMode(m);
  }

  /// Boots the in-process server and publishes a loopback [ApiConfig].
  /// Throws if [ModeSelectViewModel] reported an error or if the runtime /
  /// ApiConfig never materialised, so callers can refuse to authenticate.
  Future<void> _bootServerMode(String venueId) async {
    final vm = _ref.read(modeSelectViewModelProvider.notifier);
    await vm.choose(AppMode.server, venueId: venueId);
    final ms = _ref.read(modeSelectViewModelProvider);
    if (ms.error != null) {
      throw StateError(ms.error!);
    }
    final rt = _ref.read(serverRuntimeProvider);
    final cfg = _ref.read(apiConfigProvider);
    if (rt == null || cfg == null) {
      throw StateError('server runtime not ready');
    }
  }

  /// Pick a server from the list.
  ///
  /// A **paired** pick promotes the stage to [StaffStage.connected], which is
  /// what re-opens the PIN pad — an unpaired row already lands the caller at
  /// the pad via [selectDiscovered], so a paired row doing less was the
  /// inconsistency that made "ganti server" a one-way door. Promoting even
  /// when the key is unchanged is the point: re-picking the server you are
  /// already on is exactly how you get back after dismissing the pad.
  void selectServer(String key) {
    final match = state.servers.where((s) => s.key == key).toList();
    if (match.isEmpty) return;
    final picked = match.first;
    state = state.copyWith(
      selectedServerKey: key,
      stage: picked.paired ? StaffStage.connected : null,
    );
    if (picked.paired) _publishApiConfig(picked);
  }

  /// The PIN pad closed without admitting anyone.
  ///
  /// The screen must not decide this. It used to — a bare
  /// `setStage(pickingServer)` in the sheet's `finally` — which is the same
  /// "second copy of where are we" that [setStage]'s comment warns about, and
  /// it dumped a still-paired device into the picker with no way back.
  ///
  /// Dismissing means *not now*, not *re-pair me*: land on the connected card
  /// (whose tap re-opens the pad) whenever there is a paired selection to land
  /// on, and fall back to the picker only when there genuinely isn't one.
  void dismissPinPad() {
    final paired = state.selectedServer?.paired ?? false;
    setStage(paired ? StaffStage.connected : StaffStage.pickingServer);
  }

  void _publishApiConfig(PairedServerInfo s) {
    final next = ApiConfig(
      baseUri: Uri.parse('https://${s.host}:${s.port}'),
      trustedFingerprint: s.fingerprint,
    );
    // No-op if unchanged: StateProvider notifies on identity, so a fresh-but-
    // equal instance would still rebuild every repo keyed on apiConfigProvider
    // and re-run their one-shot bootstrap (401s while unauthenticated → empty
    // tables until restart). See ApiConfig.== .
    if (_ref.read(apiConfigProvider) == next) return;
    _ref.read(apiConfigProvider.notifier).state = next;
  }

  void clearAdmission() {
    if (state.admission != null) {
      state = state.copyWith(admission: null);
    }
  }

  void clearPairingError() {
    if (state.pairingError != null) {
      state = state.copyWith(pairingError: null);
    }
  }

  /// Verifies [pin] against the currently selected server.
  /// Returns `null` on success, or a user-facing error message on failure.
  Future<String?> verifyPin(String pin) async {
    SatLog.vm('PinVM verifyPin len=${pin.length}');
    final cfg = _ref.read(apiConfigProvider);
    final sel = state.selectedServer;
    if (cfg == null || sel == null || !sel.paired) {
      return _ref.read(l10nProvider).pinPickServerFirst;
    }
    final deviceId = await _storage.readDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      SatLog.vm('PinVM verifyPin missing deviceId');
      return _ref.read(l10nProvider).pinDeviceNotPaired;
    }
    try {
      await _persistMode(AppMode.client);
    } catch (e) {
      SatLog.vm('PinVM verifyPin persist fail $e');
      return _ref.read(l10nProvider).pinSetupFailed;
    }
    final ok = await _auth.signInWithPin(pin);
    if (ok) {
      SatLog.vm('PinVM verifyPin result=ok');
      return null;
    }
    final err = _ref.read(authStateProvider).error;
    SatLog.vm('PinVM verifyPin result=fail err=$err');
    return err ?? _ref.read(l10nProvider).authWrongPin;
  }

  /// Run one admission and hand back its outcome.
  ///
  /// NB: do NOT persist Server mode up front — a super-admin login must not
  /// mark this device as a server. The admin path persists Server mode inside
  /// `bootServer` (ModeSelect.choose); a super admin boots no server (ADR-0016).
  /// Firebase gates entry + eligibility first; the embedded server boots only
  /// once that passes (ADR-0015), and a boot failure comes back as
  /// [AdmissionServerBootFailed] rather than an exception to unpick here.
  Future<AdmissionOutcome> submitAdmin({
    required String email,
    required String password,
    bool freshProfile = false,
  }) async {
    if (state.adminBusy) return const AdmissionCancelled();
    SatLog.vm('PinVM submitAdmin fresh=$freshProfile');
    state = state.copyWith(adminBusy: true, admission: null);
    final outcome = await _auth.signInAsAdmin(
      email: email,
      password: password,
      bootServer: _bootServerMode,
      freshProfile: freshProfile,
    );
    SatLog.vm('PinVM submitAdmin outcome=${outcome.runtimeType}');
    state = state.copyWith(adminBusy: false, admission: outcome);
    return outcome;
  }

  /// Abandon an admission in flight. Optimistically drops `adminBusy` so the
  /// form comes back the instant it is pressed — the repository's attempt token
  /// is what guarantees the abandoned run cannot write over us afterwards.
  void cancelAdmin() {
    if (!state.adminBusy) return;
    SatLog.vm('PinVM cancelAdmin');
    _auth.cancelAdmission();
    state = state.copyWith(
      adminBusy: false,
      admission: const AdmissionCancelled(),
    );
  }

  /// LAN-trusted auto-claim for a server surfaced via mDNS. POSTs to
  /// `/pair/auto-claim` over a TLS-pinned client; on success persists the
  /// pairing and selects the entry so the user can immediately enter PIN.
  Future<bool> selectDiscovered(PairedServerInfo s) async {
    if (state.pairingBusy) return false;
    SatLog.vm('PinVM autoClaim ${s.host}:${s.port}');
    state = state.copyWith(
      pairingBusy: true,
      pairingError: null,
      selectedServerKey: s.key,
    );
    await _persistMode(AppMode.client);
    // Clear any stale session token so a previously-paired token cannot
    // silently authenticate the user — Staff PIN entry is required.
    await _storage.clearSession();
    try {
      final deviceId = await _storage.readDeviceId() ?? const Uuid().v4();
      await _storage.writeDeviceId(deviceId);
      final inner = ApiClient.buildPinnedHttpClient(
        s.fingerprint,
        isLoopback: ApiClient.isLoopbackHost(s.host),
      );
      final client = http_io.IOClient(inner);
      Map<String, dynamic> body;
      try {
        final uri = Uri(
          scheme: 'https',
          host: s.host,
          port: s.port,
          path: '/pair/auto-claim',
        );
        final r = await client.post(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'deviceId': deviceId,
            'deviceLabel': 'satset-client',
            'publicKey': '',
          }),
        );
        if (r.statusCode >= 400) {
          throw StateError('auto-claim failed ${r.statusCode}');
        }
        body = jsonDecode(r.body) as Map<String, dynamic>;
      } finally {
        client.close();
      }
      final res = PairClaimResponseDto.fromJson(body);
      if (res.fingerprint.toLowerCase() != s.fingerprint.toLowerCase()) {
        throw StateError('fingerprint mismatch — refuse to trust server');
      }
      await _storage.writeServerFingerprint(s.fingerprint);
      await _storage.writeServerCert(res.serverPublicKey);
      await _prefs.setPairedHost(s.host);
      await _prefs.setPairedPort(s.port);
      _publishApiConfig(s);
      await refreshPairedServers();
      state = state.copyWith(pairingBusy: false, selectedServerKey: s.key);
      return true;
    } catch (e) {
      SatLog.vm('PinVM autoClaim fail $e');
      state = state.copyWith(
        pairingBusy: false,
        pairingError: _ref.read(l10nProvider).pinAutoClaimFailed('$e'),
      );
      return false;
    }
  }

  Future<bool> connectManualAddress(String address) async {
    final cleanAddr = address.trim();
    if (cleanAddr.isEmpty) {
      state = state.copyWith(
        pairingError: _ref.read(l10nProvider).pinManualEntryEmpty,
      );
      return false;
    }

    state = state.copyWith(pairingBusy: true, pairingError: null);

    String host = cleanAddr;
    int port = 7443;
    if (cleanAddr.contains(':')) {
      final parts = cleanAddr.split(':');
      host = parts[0].trim();
      if (parts.length > 1) {
        port = int.tryParse(parts[1].trim()) ?? 7443;
      }
    } else {
      final parts = cleanAddr.split('.');
      if (parts.length == 5) {
        final allNumbers = parts.every((p) => int.tryParse(p.trim()) != null);
        if (allNumbers) {
          host = parts.sublist(0, 4).map((p) => p.trim()).join('.');
          port = int.tryParse(parts[4].trim()) ?? 7443;
        }
      }
    }

    if (host.isEmpty) {
      state = state.copyWith(
        pairingBusy: false,
        pairingError: _ref.read(l10nProvider).pinManualEntryEmpty,
      );
      return false;
    }

    String? fingerprint;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 4)
      ..badCertificateCallback = (cert, h, p) {
        fingerprint = sha256.convert(cert.der).toString().toLowerCase();
        return true;
      };

    try {
      final uri = Uri.parse('https://$host:$port/healthz');
      final request = await client.getUrl(uri);
      final response = await request.close();
      await response.drain();
    } catch (e) {
      SatLog.vm('Manual connection fingerprint probe error to $host:$port: $e');
    } finally {
      client.close();
    }

    if (fingerprint == null || fingerprint!.isEmpty) {
      state = state.copyWith(
        pairingBusy: false,
        pairingError: _ref.read(l10nProvider).pinManualEntryNotFound,
      );
      return false;
    }

    final s = PairedServerInfo(
      host: host,
      port: port,
      fingerprint: fingerprint!,
      label: host,
      paired: false,
    );

    state = state.copyWith(pairingBusy: false);
    final ok = await selectDiscovered(s);
    return ok;
  }

  @override
  void dispose() {
    unawaited(_mdnsSub?.cancel());
    unawaited(_mdns.stop());
    super.dispose();
  }
}

final pinViewModelProvider =
    StateNotifierProvider.autoDispose<PinViewModel, PinState>((ref) {
      final prefs = ref.watch(prefsServiceProvider).requireValue;
      final storage = ref.watch(secureStorageServiceProvider);
      final mdns = ref.watch(mdnsBrowserServiceProvider);
      return PinViewModel(ref, prefs, storage, mdns);
    });
