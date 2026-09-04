import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/fleet_service.dart';
import 'package:satset/domain/models/release_gate.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/features/fleet/_fleet_widgets.dart';
import 'package:satset/ui/features/fleet/venue_edit_screen.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// The super admin's cloud control plane. Reads venues live from Firestore;
/// every mutation goes through a Cloud Function. Lives outside the app shell (a
/// super admin never pairs / runs a local server). See ADR-0016.
///
/// An urgency-sorted list of venue tiles over a search box and a lens row.
/// Tapping a tile opens the [VenueEditScreen], which owns everything a super
/// admin does to one venue: access, subscription, accounts, identity, delete.
/// The kill switch is also kept on the tile's `⋮` as the fast path, so cutting
/// a venue off mid-service never requires opening it first.
///
/// The lenses are **not** a partition — a venue that has stopped paying appears
/// under both `Perlu tindakan` and `Tagihan`. They are the three questions the
/// operator arrives with ("what is on fire", "who owes me", "what did I turn
/// off"), and forcing them to be disjoint would mean the money question hides
/// the venues that most need it asked.
enum _Lens { all, trouble, billing, off }

/// The four groups the urgency rank collapses to for layout purposes. Six ranks
/// is the right granularity for *ordering*; four is the right one for *seeing*,
/// and a heading per rank would be six headings on a screen that often has one
/// venue in trouble.
enum _Band { trouble, ending, idle, running }

class FleetConsoleScreen extends ConsumerStatefulWidget {
  const FleetConsoleScreen({super.key});

  @override
  ConsumerState<FleetConsoleScreen> createState() => _FleetConsoleScreenState();
}

class _FleetConsoleScreenState extends ConsumerState<FleetConsoleScreen> {
  bool _busy = false;
  final _search = TextEditingController();
  String _query = '';
  _Lens _lens = _Lens.all;

  FleetService get _svc => ref.read(fleetServiceProvider);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    if (_busy) return;
    if (_offline) {
      fleetToast(context, context.l10n.fltNotConnected, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) fleetToast(context, okMsg);
    } catch (e) {
      if (mounted) fleetToast(context, fleetErrText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// True while Firestore is serving the cache. Locks every mutation — a super
  /// admin has no offline mode, so an action taken now fails, and it would fail
  /// into a toast the operator reads as a result.
  bool get _offline => ref.read(fleetOfflineProvider);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final venues = ref.watch(fleetVenuesProvider);
    final offline = ref.watch(fleetOfflineProvider);
    // Offline duration and lockout risk are derived from `now`, so the list has
    // to rebuild on the clock, not only on a snapshot. See [fleetTickProvider].
    ref.watch(fleetTickProvider);

    final all = venues.valueOrNull ?? const <Venue>[];
    // The kicker carries the one aggregate no lens chip does: how much of the
    // fleet is actually serving right now. The counts live on the chips, so
    // repeating them up here would be the heading restating itself.
    final live = all.where(_isLive).length;

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        // One column, capped. A venue row is a name, an address and a few
        // facts; stretched across a landscape tablet it becomes a title, a
        // metre of nothing, and a `⋮` the thumb has to travel to.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: fleetColumnMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  // Left edge is the list's, not its own: "Fleet" sitting 4px
                  // right of every tile under it read as a wobble on the one
                  // vertical the eye actually tracks down this screen.
                  padding: const EdgeInsets.fromLTRB(
                    fleetGutter,
                    Sp.s4,
                    Sp.s3,
                    Sp.s2,
                  ),
                  child: FleetHeader(
                    kicker: all.isEmpty
                        ? context.l10n.fltKicker
                        : context.l10n.fltOnlineOf(live, all.length),
                    title: context.l10n.fltConsoleTitle,
                    // Creating a venue is the rarest act here and it used to
                    // hold row 0 of a list whose job is showing trouble first.
                    // Moved to the toolbar so the top of the list is the top of
                    // the problem.
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SatButton.primary(
                          label: context.l10n.fltNewVenue,
                          icon: Icons.add,
                          size: SatButtonSize.sm,
                          onTap: _busy || offline ? null : _createVenueDialog,
                        ),
                        const SizedBox(width: Sp.s1),
                        // Fleet-wide, not per-venue — so it sits in the
                        // toolbar and not on a tile. See ADR-0130.
                        SatIconButton.plain(
                          icon: Icons.system_update_alt_rounded,
                          tooltip: context.l10n.fltReleaseGate,
                          onTap: _busy || offline ? null : _releaseGateDialog,
                        ),
                        const SizedBox(width: Sp.s1),
                        SatIconButton.plain(
                          icon: Icons.logout,
                          tooltip: context.l10n.logout,
                          onTap: _confirmSignOut,
                        ),
                      ],
                    ),
                  ),
                ),
                if (offline) const FleetOfflineBanner(),
                // Search and lenses only exist once the fleet is big enough to
                // hide something. On two venues they are two rows of chrome
                // over the entire answer.
                if (all.length >= 6) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      fleetGutter,
                      Sp.s2,
                      fleetGutter,
                      0,
                    ),
                    child: SatField.search(
                      controller: _search,
                      hint: context.l10n.fltSearchHint,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      suffix: _query.isEmpty
                          ? null
                          : SatIconButton.plain(
                              icon: Icons.close,
                              tooltip: context.l10n.hapusPencarian,
                              size: 32,
                              onTap: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                  _lensRow(all),
                ],
                if (_busy)
                  LinearProgressIndicator(minHeight: 2, color: sc.accentText)
                else
                  const SizedBox(height: Sp.sHair),
                Expanded(child: _venueList(sc, venues, offline)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lenses carrying their own counts. The count is what turns a filter row
  /// into the fleet's summary: "3" beside `Tagihan` answers the operator's
  /// question outright, and tapping it is the follow-up rather than a separate
  /// control somewhere else.
  Widget _lensRow(List<Venue> all) {
    final now = SatClock.now();
    int n(_Lens l) => all.where((v) => _matchesLens(v, l, now)).length;
    // Sizes to its chips instead of to a fixed 56. A chip grows with the system
    // text scale and the box did not, so at 200% the row clipped the counts —
    // which are the only reason the row is worth a line of the screen.
    // Horizontal inset rides *inside* the scroll view so the chips bleed past
    // the gutter when scrolled rather than being cut off at it.
    return Padding(
      padding: const EdgeInsets.only(top: Sp.s3, bottom: Sp.s1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: fleetGutter),
        child: Row(
          children: [
            for (final l in _Lens.values) ...[
              SatChip.select(
                label: _lensLabel(l),
                count: n(l),
                selected: _lens == l,
                onTap: () => setState(() => _lens = l),
              ),
              if (l != _Lens.values.last) const SizedBox(width: Sp.s2),
            ],
          ],
        ),
      ),
    );
  }

  String _lensLabel(_Lens l) => switch (l) {
    _Lens.all => context.l10n.mnaAll,
    _Lens.trouble => context.l10n.fltLensTrouble,
    _Lens.billing => context.l10n.fltLensBilling,
    _Lens.off => context.l10n.fltLensOff,
  };

  bool _matchesLens(Venue v, _Lens l, DateTime now) => switch (l) {
    _Lens.all => true,
    _Lens.trouble => fleetUrgencyRank(v, now) <= 2,
    _Lens.billing =>
      fleetBillingTrouble(v, now) || fleetSubscriptionEnding(v, now) != null,
    _Lens.off => v.status != AdminStatus.active,
  };

  bool _matchesQuery(Venue v) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return v.name.toLowerCase().contains(q) ||
        v.address.toLowerCase().contains(q);
  }

  /// Signing out of a cloud-only console with no cached session is a one-way
  /// door: getting back in needs the credentials, which the operator may not
  /// carry. One tap next to the fleet's kill switches was too little friction.
  void _confirmSignOut() => _confirm(
    context.l10n.fltSignOutTitle,
    context.l10n.fltSignOutBody,
    context.l10n.fltSignOut,
    () => ref.read(authStateProvider.notifier).signOut(),
  );

  Widget _venueList(
    SatColors sc,
    AsyncValue<List<Venue>> venues,
    bool offline,
  ) {
    return venues.when(
      loading: () => Center(child: SatSpinner(size: SatSpinnerSize.md)),
      error: (e, _) => _errorBox(sc, e),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Sp.s6),
              child: SatEmpty(
                icon: Icons.storefront_outlined,
                title: context.l10n.fltEmptyNoVenue,
                body: context.l10n.fltEmptyNoVenueBody,
              ),
            ),
          );
        }

        final now = SatClock.now();
        // Trouble on top — the SA's job is catching the few venues in it among
        // many. Rank by *kind* of trouble first (lockout beats unpaid beats
        // expiring beats killed), then within the lockout band by how little
        // time is left, then alphabetically. Sorting on lockout alone left an
        // overdue venue filed under W.
        final sorted =
            [
              ...list.where(
                (v) => _matchesQuery(v) && _matchesLens(v, _lens, now),
              ),
            ]..sort((a, b) {
              final ka = _urgencyRank(a), kb = _urgencyRank(b);
              if (ka != kb) return ka.compareTo(kb);
              final ra = _lockoutRisk(a), rb = _lockoutRisk(b);
              if (ra != null && rb != null && ra != rb) return ra.compareTo(rb);
              return a.name.compareTo(b.name);
            });

        // Distinct from the empty fleet above: nothing is wrong, the operator
        // has simply narrowed past every row. The way out is named, because a
        // lens left on from five minutes ago is invisible once you have stopped
        // looking at the chip that set it.
        if (sorted.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Sp.s6),
              child: SatEmpty(
                icon: Icons.search_off_rounded,
                title: context.l10n.fltEmptyNoMatch,
                body: _query.isEmpty
                    ? context.l10n.fltEmptyLensBody(_lensLabel(_lens))
                    : _lens == _Lens.all
                    ? context.l10n.fltEmptyQueryBody(_query)
                    : context.l10n.fltEmptyQueryLensBody(
                        _query,
                        _lensLabel(_lens),
                      ),
              ),
            ),
          );
        }

        // The sort already groups the list; the layout just has to draw the
        // seams. Contiguous runs of the same band, tight inside (Sp.s2) and
        // generous between (Sp.s8) — the rhythm is what makes "three venues
        // need me" legible before a single row is read.
        final bands = <(_Band, List<Venue>)>[];
        for (final v in sorted) {
          final b = _bandOf(v);
          if (bands.isEmpty || bands.last.$1 != b) bands.add((b, <Venue>[]));
          bands.last.$2.add(v);
        }
        // A label on the only band is noise: it names what the whole screen
        // already is.
        final labelled = bands.length > 1;
        var step = 0;

        return ListView(
          // Bottom inset was 96 — a FAB's worth of clearance on a screen with
          // no FAB, so the last venue floated a third of a thumb above nothing.
          padding: const EdgeInsets.fromLTRB(
            fleetGutter,
            Sp.s3,
            fleetGutter,
            Sp.s12,
          ),
          children: [
            for (var bi = 0; bi < bands.length; bi++) ...[
              if (bi > 0) const SizedBox(height: Sp.s8),
              if (labelled)
                Padding(
                  // Flush with the tiles it heads. Indented, it read as a
                  // fourth level of nesting on a list that has one.
                  padding: const EdgeInsets.only(bottom: Sp.s2),
                  child: Text(
                    '${_bandLabel(bands[bi].$1)} · ${bands[bi].$2.length}',
                    style: SatType.caption(color: _bandTint(sc, bands[bi].$1)),
                  ),
                ),
              for (var ri = 0; ri < bands[bi].$2.length; ri++) ...[
                Reveal(
                  // Capped: at 55ms a step an uncapped stagger makes venue #40
                  // wait 2.2s to appear, on the screen whose whole job is a
                  // fast scan for trouble.
                  index: (++step).clamp(0, 8),
                  animKey: bands[bi].$2[ri].id,
                  child: _venueTile(sc, bands[bi].$2[ri], offline),
                ),
                if (ri != bands[bi].$2.length - 1)
                  const SizedBox(height: Sp.s2),
              ],
            ],
          ],
        );
      },
    );
  }

  _Band _bandOf(Venue v) => switch (_urgencyRank(v)) {
    0 || 1 || 2 => _Band.trouble,
    3 => _Band.ending,
    4 => _Band.idle,
    _ => _Band.running,
  };

  String _bandLabel(_Band b) => switch (b) {
    _Band.trouble => context.l10n.fltBandTrouble,
    _Band.ending => context.l10n.fltBandEnding,
    _Band.idle => context.l10n.fltBandIdle,
    _Band.running => context.l10n.fltBandRunning,
  };

  /// Only the bands that want something get a tint. A heading that says
  /// "BERJALAN" in green is decoration — the news is the ones above it.
  Color _bandTint(SatColors sc, _Band b) => switch (b) {
    _Band.trouble => sc.urgent,
    _Band.ending => sc.warn,
    _ => sc.textMd,
  };

  // The derivations themselves live in `_fleet_widgets.dart`, pure and
  // `now`-taking so a test can pin them; these are the screen's clock.
  int _urgencyRank(Venue v) => fleetUrgencyRank(v, SatClock.now());

  bool _billingTrouble(Venue v) => fleetBillingTrouble(v, SatClock.now());

  bool _paidUntilPassed(Venue v) => fleetPaidUntilPassed(v, SatClock.now());

  Duration? _endingSoon(Venue v) => fleetSubscriptionEnding(v, SatClock.now());

  bool _isLive(Venue v) {
    final last = v.lastSeenAt;
    return last != null &&
        SatClock.now().difference(last) < const Duration(seconds: 90);
  }

  Widget _venueTile(SatColors sc, Venue v, bool offline) {
    // Glyph as well as tint: a killed venue reads as killed without colour.
    final vis = fleetStatusVisual(
      sc,
      v.status,
      l10n: context.l10n,
      activeIcon: Icons.storefront_outlined,
    );
    final billingBad = _billingTrouble(v);
    return FleetTile(
      icon: vis.icon,
      tint: vis.tint,
      title: v.name.isEmpty ? context.l10n.fltUnnamed : v.name,
      sub: v.address.isEmpty ? null : v.address,
      meta: _metaLine(v),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => VenueEditScreen(venue: v)),
      ),
      // Pills are trouble only. A healthy venue carries none, so on a fleet
      // that is fine the screen has no colour in it at all — and the one venue
      // that is not fine is the only thing on it that does.
      pills: [
        if (v.status != AdminStatus.active)
          fleetPill(sc, vis.label, vis.tint, vis.soft),
        if (billingBad)
          fleetPill(sc, _billingBadText(v), sc.urgent, sc.urgentSoft),
        if (_endingSoon(v) case final left?)
          fleetPill(
            sc,
            context.l10n.fltEndsIn(_daysLeftText(left)),
            sc.warn,
            sc.warnSoft,
          ),
        if (_lockoutRisk(v) case final risk?)
          fleetPill(
            sc,
            _lockoutText(risk),
            risk <= Duration.zero ? sc.urgent : sc.warn,
            risk <= Duration.zero ? sc.urgentSoft : sc.warnSoft,
          ),
      ],
      trailing: fleetMenu(
        sc,
        enabled: !_busy && !offline,
        tooltip: context.l10n.fltVenueActions,
        // `Aktifkan` is withheld from a venue past its subscription cutoff — the
        // sweep would only take it down again, and the way back is a future date
        // set in the editor. See ADR-0076.
        items: {
          if (v.status != AdminStatus.active &&
              !fleetCutoffDue(v, SatClock.now()))
            'activate': context.l10n.fltActivate,
          if (v.status != AdminStatus.suspended)
            'suspend': context.l10n.fltSuspendKill,
        },
        dangerKeys: const {},
        onSelected: (k) => _onVenueAction(v, k),
      ),
    );
  }

  /// The venue's steady facts on one line: plan first, because the lens the
  /// operator is holding is usually the subscription; then paid-through while
  /// it is still ahead of us, then whether the venue is up. None of these is
  /// news, so none of them gets a container.
  String _metaLine(Venue v) {
    final parts = <String>[fleetPlanLabel(v.plan)];
    final until = v.paidUntil;
    // Suppressed while the "Berakhir N hari lagi" pill is up. The pill is the
    // same date having already done the arithmetic, so carrying both put "s/d
    // 12 Agu" and "Berakhir 5 hari lagi" on one tile — and the quiet copy of a
    // fact is what teaches the eye to stop reading the loud one.
    if (until != null && !_paidUntilPassed(v) && _endingSoon(v) == null) {
      parts.add(context.l10n.fltPaidUntil(formatShortDateId(until)));
    }
    parts.add(_offlineText(v));
    return parts.join('  ·  ');
  }

  /// A lapsed term, and the date the sweep acts on it — a venue that is merely
  /// late reads differently from one about to go dark, and the operator's whole
  /// job in that gap is to get it renewed before the second one happens.
  String _billingBadText(Venue v) {
    final cutoff = venueCutoffAt(v);
    if (cutoff == null) return context.l10n.fltBillingOverdue;
    return fleetCutoffDue(v, SatClock.now())
        ? context.l10n.fltSuspendedOn(formatShortDateId(cutoff))
        : context.l10n.fltOverdueDiesOn(formatShortDateId(cutoff));
  }

  String _daysLeftText(Duration left) => left.inDays >= 1
      ? context.l10n.fltDaysLeft(left.inDays)
      : context.l10n.fltToday;

  void _onVenueAction(Venue v, String k) {
    switch (k) {
      case 'activate':
        _run(
          () => _svc.setVenueStatus(v.id, AdminStatus.active),
          context.l10n.fltVenueActivated(v.name),
        );
      case 'suspend':
        _confirm(
          context.l10n.fltSuspendTitle(v.name),
          context.l10n.fltSuspendBody,
          context.l10n.fltSuspend,
          () => _run(
            () => _svc.setVenueStatus(v.id, AdminStatus.suspended),
            context.l10n.fltVenueSuspended(v.name),
          ),
        );
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  /// Validation lives **inside** the dialog: the old version checked the name
  /// after the sheet had already popped, so an empty name closed the dialog and
  /// created nothing, silently. The dialog also *owns* its controllers — see
  /// [NewVenueDialog].
  Future<void> _createVenueDialog() async {
    final okMsg = context.l10n.fltVenueCreated;
    final draft = await showSatDialog<VenueDraft>(
      context,
      builder: (_) => const NewVenueDialog(),
    );
    if (draft == null) return;
    await _run(
      () => _svc.createVenue(
        name: draft.name,
        address: draft.address,
        plan: draft.plan,
      ),
      okMsg,
    );
  }

  /// The manual override on the gate CI writes from the tag (ADR-0130). Rare,
  /// fleet-wide, and the only way back from a `-breaking` tag that blocked a
  /// fleet mid-service — so it is a toolbar button and not a venue action.
  Future<void> _releaseGateDialog() async {
    final okMsg = context.l10n.saved;
    final current =
        ref.read(fleetReleaseGateProvider).valueOrNull ?? ReleaseGate.unknown;
    final draft = await showSatDialog<ReleaseGate>(
      context,
      builder: (_) => ReleaseGateDialog(current: current),
    );
    if (draft == null) return;
    await _run(
      () => _svc.setReleaseGate(
        min: draft.min ?? '',
        recommended: draft.recommended ?? '',
        latest: draft.latest ?? '',
      ),
      okMsg,
    );
  }

  /// [confirmLabel] names the act — "Tangguhkan", "Blokir", "Keluar". A danger
  /// button that just says "Lanjut" makes every confirmation the same tap.
  void _confirm(
    String title,
    String body,
    String confirmLabel,
    VoidCallback onYes,
  ) {
    final sc = context.sat;
    showSatDialog<void>(
      context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(title, style: SatType.h3(color: sc.textHi)),
        content: Text(body, style: SatType.bodyM(color: sc.textMd)),
        actions: [
          SatButton.ghost(
            label: context.l10n.cancel,
            onTap: () => Navigator.pop(ctx),
          ),
          SatButton.danger(
            label: confirmLabel,
            onTap: () {
              Navigator.pop(ctx);
              onYes();
            },
          ),
        ],
      ),
    );
  }

  // ── Small pieces ───────────────────────────────────────────────────────────

  /// The load is the first thing to fail on an online-only surface, so it gets
  /// a way back rather than a dead end.
  Widget _errorBox(SatColors sc, Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Sp.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: Sp.s10, color: sc.urgent),
          const SizedBox(height: Sp.s3),
          Text(
            context.l10n.fltLoadFailed,
            style: SatType.labelL(color: sc.textHi),
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            fleetErrText(e),
            textAlign: TextAlign.center,
            style: SatType.bodyM(color: sc.textMd),
          ),
          const SizedBox(height: Sp.s4),
          SatButton.outline(
            label: context.l10n.retry,
            icon: Icons.refresh,
            onTap: () => ref.invalidate(fleetVenuesProvider),
          ),
        ],
      ),
    ),
  );

  Duration? _lockoutRisk(Venue v) => fleetLockoutRisk(v, SatClock.now());

  /// Risk-framed copy: from the cloud the SA cannot tell a venue that closed its
  /// app (will block on restart) from one whose server stayed up but lost
  /// internet (still serving) — so never assert "locked", only the risk.
  String _lockoutText(Duration rem) => rem <= Duration.zero
      ? context.l10n.fltLockoutPast
      : context.l10n.fltLockoutNear(rem.inHours);

  String _offlineText(Venue v) {
    final last = v.lastSeenAt;
    if (last == null) return context.l10n.fltNeverOnline;
    final d = SatClock.now().difference(last);
    if (d.inSeconds < 90) return context.l10n.fltOnline;
    if (d.inMinutes < 60) return context.l10n.fltOfflineMinutes(d.inMinutes);
    if (d.inHours < 24) return context.l10n.fltOfflineHours(d.inHours);
    return context.l10n.fltOfflineDays(d.inDays);
  }
}

/// What [NewVenueDialog] pops with — the three fields the console needs to
/// call `createVenue`, read once, at the moment of the tap.
typedef VenueDraft = ({String name, String address, String plan});

/// The create-venue form, as a widget that **owns its controllers**.
///
/// They used to live in `_createVenueDialog` and be disposed in its `finally`.
/// But `showDialog`'s future completes when the route is *popped*, not when it
/// has finished animating out, and the dialog's fields keep rebuilding through
/// that transition — so the `finally` handed a disposed controller to a live
/// `TextField`. On the tablet that was "A TextEditingController was used after
/// being disposed", then a torn-down subtree still holding inherited
/// dependencies, and a red screen over the whole console: cancelling the dialog
/// killed the app. Owning them here ties their lifetime to the dialog's own
/// element, which is disposed when the route is really gone.
class NewVenueDialog extends StatefulWidget {
  const NewVenueDialog({super.key});

  @override
  State<NewVenueDialog> createState() => _NewVenueDialogState();
}

class _NewVenueDialogState extends State<NewVenueDialog> {
  final _name = TextEditingController();
  final _addr = TextEditingController();
  String _plan = venuePlanTrial;

  @override
  void dispose() {
    _name.dispose();
    _addr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final valid = _name.text.trim().isNotEmpty;
    return AlertDialog(
      backgroundColor: sc.bg1,
      title: Text(
        context.l10n.fltNewVenue,
        style: SatType.h3(color: sc.textHi),
      ),
      // Scrollable, and the name field does **not** autofocus. The keyboard
      // takes half a landscape tablet; raised on open it left the form 183px
      // overflowed, actions painted across the Alamat field under yellow tape.
      // Not raising it means the operator sees all three fields before typing,
      // and `scrollable` — which puts title, content and actions in one scroll
      // view — absorbs the keyboard when it does come up, instead of crushing
      // the content into whatever strip the fixed title and actions leave.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SatField.text(
            controller: _name,
            label: context.l10n.fltVenueName,
            hint: '',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Sp.s3),
          SatField.text(
            controller: _addr,
            label: context.l10n.sysAddress,
            hint: context.l10n.resOptional,
          ),
          const SizedBox(height: Sp.s3),
          // Plan only. Term and price belong to the editor (ADR-0076) — two
          // places that can set a term are two places that will drift, and a
          // trial created here with no date simply never lapses until someone
          // opens it and decides how long it runs.
          fleetPlanDropdown(
            value: _plan,
            onChanged: (x) => setState(() => _plan = x),
          ),
        ],
      ),
      actions: [
        SatButton.ghost(
          label: context.l10n.cancel,
          onTap: () => Navigator.pop(context),
        ),
        SatButton.primary(
          label: context.l10n.save,
          onTap: valid
              ? () => Navigator.pop(context, (
                  name: _name.text,
                  address: _addr.text,
                  plan: _plan,
                ))
              : null,
        ),
      ],
    );
  }
}

/// The release gate override (ADR-0130). Three version fields, no version
/// picker and no release list: the super admin is reading the tag they just
/// pushed off another screen, and a picker here would need its own source of
/// truth for what has been built.
///
/// Owns its controllers for the reason [NewVenueDialog] does. Validation is
/// inside, and it is the same rule the callable enforces — a dialog that lets
/// an invalid ordering through would pop, fire, and fail into a toast.
class ReleaseGateDialog extends StatefulWidget {
  const ReleaseGateDialog({super.key, required this.current});

  final ReleaseGate current;

  @override
  State<ReleaseGateDialog> createState() => _ReleaseGateDialogState();
}

class _ReleaseGateDialogState extends State<ReleaseGateDialog> {
  late final _min = TextEditingController(text: widget.current.min ?? '');
  late final _rec = TextEditingController(
    text: widget.current.recommended ?? '',
  );
  late final _latest = TextEditingController(text: widget.current.latest ?? '');

  @override
  void dispose() {
    _min.dispose();
    _rec.dispose();
    _latest.dispose();
    super.dispose();
  }

  /// Empty is legal everywhere — it clears that floor. Anything else must parse
  /// and must not break the min ≤ recommended ≤ latest ordering, comparing only
  /// the pairs that are actually set.
  bool get _valid {
    final v = [_min.text.trim(), _rec.text.trim(), _latest.text.trim()];
    if (v.any((s) => s.isNotEmpty && parseVersion(s) == null)) return false;
    final set = [for (final s in v) s.isEmpty ? null : s];
    for (var i = 0; i < set.length; i++) {
      for (var j = i + 1; j < set.length; j++) {
        if (set[i] != null &&
            set[j] != null &&
            compareVersions(set[i], set[j]) > 0) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final valid = _valid;
    return AlertDialog(
      backgroundColor: sc.bg1,
      title: Text(
        context.l10n.fltReleaseGate,
        style: SatType.h3(color: sc.textHi),
      ),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SatField.text(
            controller: _min,
            label: context.l10n.fltReleaseGateMin,
            hint: '1.2.3',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Sp.s3),
          SatField.text(
            controller: _rec,
            label: context.l10n.fltReleaseGateRecommended,
            hint: '1.2.3',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Sp.s3),
          SatField.text(
            controller: _latest,
            label: context.l10n.fltReleaseGateLatest,
            hint: '1.2.3',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Sp.s2),
          Text(
            valid
                ? context.l10n.fltReleaseGateHint
                : context.l10n.fltReleaseGateInvalid,
            style: SatType.bodyS(color: valid ? sc.textDim : sc.urgent),
          ),
        ],
      ),
      actions: [
        SatButton.ghost(
          label: context.l10n.cancel,
          onTap: () => Navigator.pop(context),
        ),
        SatButton.primary(
          label: context.l10n.save,
          onTap: valid
              ? () => Navigator.pop(
                  context,
                  ReleaseGate(
                    min: _min.text.trim(),
                    recommended: _rec.text.trim(),
                    latest: _latest.text.trim(),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
