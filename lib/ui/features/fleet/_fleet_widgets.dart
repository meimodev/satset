import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Shared visual language for the Fleet console + venue editor, so the two
/// surfaces read as one system. Venue tiles and admin rows are the same
/// [FleetTile]; status stays out of the pill row and rides the leading icon —
/// but as **tint plus glyph**, never tint alone (see CONTEXT.md "Fleet
/// console"). An active venue used to differ from a killed one only by the
/// icon's hue, which a red/green-blind operator cannot read.

/// Status → (tint, soft bg, label, glyph). One source of truth for both venue
/// tiles (kill switch) and admin rows (per-operator ban).
///
/// [activeIcon] is what the row *is* when nothing is wrong — a storefront for a
/// venue, a person for an admin. The non-active glyphs are the same for both:
/// what happened to the row matters more than what kind of row it is.
({Color tint, Color soft, String label, IconData icon}) fleetStatusVisual(
  SatColors sc,
  AdminStatus s, {
  required IconData activeIcon,
}) {
  return switch (s) {
    AdminStatus.active => (
      tint: sc.success,
      soft: sc.successSoft,
      label: 'AKTIF',
      icon: activeIcon,
    ),
    AdminStatus.suspended => (
      tint: sc.warn,
      soft: sc.warnSoft,
      label: 'TANGGUH',
      icon: Icons.pause_circle_outline,
    ),
    AdminStatus.banned => (
      tint: sc.urgent,
      soft: sc.urgentSoft,
      label: 'BLOKIR',
      icon: Icons.block,
    ),
    AdminStatus.unknown => (
      tint: sc.textLo,
      soft: sc.bg3,
      label: '?',
      icon: Icons.help_outline,
    ),
  };
}

// ── Shared page metrics ─────────────────────────────────────────────────────

/// The gutter and the column cap both fleet surfaces run on.
///
/// Shared because the console pushes straight into the editor: two screens one
/// tap apart on different gutters make every push slide the content sideways,
/// and a list capped to a readable column that opens into a full-bleed form
/// throws away the line length it was capped for. On a landscape tablet the
/// uncapped editor stretched a two-field address form across a metre.
const fleetGutter = Sp.s4;
const fleetColumnMax = 720.0;

// ── Subscription ────────────────────────────────────────────────────────────

/// The plans the console offers. The wire takes any string (`setVenueBilling`
/// trims and stores it verbatim), which is exactly why the *client* holds a
/// closed list: a plan typed by hand is `pro` on one venue and `Pro ` on the
/// next, and nothing downstream can group them again.
const fleetPlans = <String, String>{
  'free': 'Free',
  'basic': 'Basic',
  'pro': 'Pro',
  'enterprise': 'Enterprise',
};

/// [fleetPlans] widened by whatever [current] already is, so opening a venue
/// that sits on a legacy plan doesn't quietly re-plan it as a side effect of
/// rendering a dropdown that cannot represent it.
List<String> fleetPlanKeys(String current) => [
  ...fleetPlans.keys,
  if (current.isNotEmpty && !fleetPlans.containsKey(current)) current,
];

String fleetPlanLabel(String key) =>
    fleetPlans[key] ?? (key.isEmpty ? '—' : key);

/// The plan picker itself, so the create dialog and the venue editor cannot
/// drift into offering two different lists of plans.
Widget fleetPlanDropdown({
  required String value,
  required ValueChanged<String> onChanged,
  String label = 'Paket',
}) => SatDropdown<String>(
  value: value,
  label: label,
  options: [
    for (final k in fleetPlanKeys(value)) SatOption(k, fleetPlanLabel(k)),
  ],
  onChanged: (x) => onChanged(x ?? value),
);

/// How far ahead of a paid-through date the console starts saying so. Two weeks
/// is an invoice's worth of notice — this screen exists to bill a venue *before*
/// it lapses, and a console that only flags the lapse has already lost the
/// month it was meant to protect.
const fleetRenewWarn = Duration(days: 14);

/// Time left on the subscription, once inside [fleetRenewWarn] and still ahead
/// of us. Null when there is no date, when it is further out than the window,
/// or when it has already passed — a lapsed date belongs to
/// [fleetBillingTrouble], and reporting it here as well would put a warn pill
/// and an urgent pill on the same row saying the same thing.
Duration? fleetSubscriptionEnding(Venue v, DateTime now) {
  final until = v.paidUntil;
  if (until == null) return null;
  final left = until.difference(now);
  return left > Duration.zero && left <= fleetRenewWarn ? left : null;
}

/// Adds [months] to a subscription without letting the day of month run over
/// into the next one: `31 Jan + 1 bulan` is 28 Feb, not 3 Mar. Two free days is
/// a rounding error until it is thirty venues wide.
DateTime fleetAddMonths(DateTime from, int months) {
  final lastDay = DateTime(from.year, from.month + months + 1, 0).day;
  return DateTime(
    from.year,
    from.month + months,
    from.day.clamp(1, lastDay),
    from.hour,
    from.minute,
  );
}

// ── Urgency + billing derivations ───────────────────────────────────────────
// Pure and `now`-taking rather than methods on the screen, so the console's
// sort order and its billing verdict can be pinned by a test: these are the two
// places on the fleet surface where a wrong answer costs someone money.

/// The console only flags a venue once it nears the lockout, to avoid alarming
/// on routine nightly closure.
const fleetLockoutWarn = Duration(hours: 48);

/// Remaining offline-grace before this venue's next cold boot would be blocked
/// by the staleness guard. Derived from `lastSeenAt` as a cloud proxy for the
/// device-local `adminConfirmedAt` (both ride the same heartbeat, so they freeze
/// together when the venue goes dark). Reuses the same
/// [FirebaseAdminService.staleAfter] the venue boot gate enforces. Null unless
/// within [fleetLockoutWarn] of the limit. See CONTEXT.md "Venue offline
/// duration".
Duration? fleetLockoutRisk(Venue v, DateTime now) {
  final last = v.lastSeenAt;
  if (last == null) return null;
  final remaining = FirebaseAdminService.staleAfter - now.difference(last);
  return remaining <= fleetLockoutWarn ? remaining : null;
}

/// True once the paid-through date is behind us, whatever the flag says.
bool fleetPaidUntilPassed(Venue v, DateTime now) {
  final until = v.paidUntil;
  return until != null && until.isBefore(now);
}

/// Overdue, or "paid" with a `paidUntil` that has already passed — the second is
/// the one nobody notices, because the flag still says paid.
bool fleetBillingTrouble(Venue v, DateTime now) =>
    v.billingStatus == 'overdue' || fleetPaidUntilPassed(v, now);

/// Sort key for the console list; lower sorts higher. 0 = at or past the
/// offline lockout, 1 = approaching it, 2 = billing needs a hand, 3 =
/// subscription about to run out, 4 = deliberately not running, 5 = fine.
///
/// Ranked by *kind* of trouble because sorting on lockout alone filed an
/// overdue venue under W. A subscription about to end outranks a suspended
/// venue on purpose: the suspension is a decision someone already made and
/// nothing is owed on it, while the renewal is an invoice nobody has sent yet.
int fleetUrgencyRank(Venue v, DateTime now) {
  final risk = fleetLockoutRisk(v, now);
  if (risk != null) return risk <= Duration.zero ? 0 : 1;
  if (fleetBillingTrouble(v, now)) return 2;
  if (fleetSubscriptionEnding(v, now) != null) return 3;
  if (v.status != AdminStatus.active) return 4;
  return 5;
}

/// A pill carrying one fleet signal (billing, offline, lockout-risk). Status is
/// deliberately *not* a pill — it lives in the tile's leading tint.
Widget fleetPill(SatColors sc, String text, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: Sp.s2, vertical: Sp.s1),
  decoration: SatBox.d(color: bg, borderRadius: SatR.a(8)),
  child: Text(text, style: SatType.caption(color: fg)),
);

/// The shared tile: leading status-tint icon box, title + sub, an optional pill
/// wrap, and a trailing action (the `⋮` quick-action menu). Whole tile is
/// tappable when [onTap] is given. Used for both venue tiles and admin rows.
class FleetTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String? sub;
  final bool subMono;

  /// Steady attributes — plan, last-seen, paid-through — as one mono line.
  /// Deliberately not pills: a pill is a container, and a container says "look
  /// at me". These never need looking at, they need to be *there* when the
  /// operator asks. Keeping them out of [pills] is what lets a pill mean
  /// trouble again.
  final String? meta;
  final List<Widget> pills;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool big;

  const FleetTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    this.sub,
    this.subMono = false,
    this.meta,
    this.pills = const [],
    this.trailing,
    this.onTap,
    this.big = true,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final radius = big ? 16.0 : 14.0;
    final iconBox = big ? 48.0 : 40.0;
    final iconSize = big ? 22.0 : 18.0;

    final body = Container(
      padding: EdgeInsets.fromLTRB(
        big ? 16 : 14,
        14,
        trailing == null ? 16 : 6,
        14,
      ),
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: SatR.a(radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: SatBox.d(
              color: tint.withValues(alpha: 0.12),
              borderRadius: SatR.a(big ? 14 : 12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: iconSize, color: tint),
          ),
          SizedBox(width: big ? 14 : 12),
          // Merged so the row announces as one unit — name, sub and pills read
          // as unrelated fragments otherwise. Scoped to the content column, not
          // the whole tile: the trailing `⋮` has to stay its own target.
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.s1),
                    child: Text(title, style: SatType.labelL(color: sc.textHi)),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: Sp.s1),
                    // `textMd`, not `textLo`: this line is the venue's address
                    // and the admin's email — the identifying detail — and
                    // `textLo` on `bg2` measures 3.86:1 on the dark palette.
                    Text(
                      sub!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: subMono
                          ? SatType.monoS(color: sc.textMd)
                          : SatType.bodyS(color: sc.textMd),
                    ),
                  ],
                  if (meta != null) ...[
                    const SizedBox(height: Sp.s1h),
                    Text(
                      meta!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SatType.caption(color: sc.textMd),
                    ),
                  ],
                  // Generous above the pills, tight above everything else: the
                  // gap is what says "the lines above are this venue, the
                  // things below are what is wrong with it".
                  if (pills.isNotEmpty) ...[
                    const SizedBox(height: Sp.s2h),
                    Wrap(spacing: Sp.s1h, runSpacing: Sp.s1h, children: pills),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: Sp.s1), trailing!],
        ],
      ),
    );

    if (onTap == null) return body;
    return Semantics(
      button: true,
      child: PressScale(
        child: Material(
          color: Colors.transparent,
          borderRadius: SatR.a(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: SatR.a(radius),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// `⋮` quick-action menu shared by venue tiles + admin rows. `danger` keys
/// render in `urgent`.
///
/// [tooltip] is required for the same reason `SatIconButton` requires one: with
/// no text child Flutter derives no semantics, and this is the control that
/// holds every destructive fleet action. `PopupMenuButton` slips past the
/// guard test's `IconButton` ban, so the requirement is enforced here.
Widget fleetMenu(
  SatColors sc, {
  required bool enabled,
  required String tooltip,
  required Map<String, String> items,
  required Set<String> dangerKeys,
  required ValueChanged<String> onSelected,
}) => PopupMenuButton<String>(
  enabled: enabled,
  tooltip: tooltip,
  icon: Icon(Icons.more_vert, color: sc.textMd),
  color: sc.bg2,
  onSelected: onSelected,
  itemBuilder: (_) => [
    for (final e in items.entries)
      PopupMenuItem(
        value: e.key,
        child: Text(
          e.value,
          style: SatType.bodyM(
            color: dangerKeys.contains(e.key) ? sc.urgent : sc.textHi,
          ),
        ),
      ),
  ],
);

/// Themed snackbar used across both fleet screens.
///
/// The error surface is an **opaque** `urgent` fill, not `urgentSoft`: the soft
/// tokens are 11–14% alpha, so a snackbar painted with one showed the screen
/// through it and read fainter than the success toast it was supposed to
/// contradict. On a console whose every mutation is a Cloud Function that can
/// be refused, a failure that looks like a success is the worst state the
/// screen can reach.
void fleetToast(BuildContext context, String msg, {bool error = false}) {
  final sc = context.sat;
  final bg = error ? sc.urgent : sc.bg3;
  final fg = error ? onFill(sc.urgent) : sc.textHi;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        backgroundColor: bg,
        duration: Duration(seconds: error ? 6 : 3),
        content: Row(
          children: [
            if (error) ...[
              Icon(Icons.error_outline, size: 18, color: fg),
              const SizedBox(width: Sp.s2),
            ],
            Expanded(child: Text(msg, style: SatType.bodyM(color: fg))),
          ],
        ),
      ),
    );
}

/// Shown while the console is reading Firestore's local cache instead of the
/// server. A super admin is online-only by design (ADR-0016) — it has no local
/// server and no offline tolerance — so stale data that renders identically to
/// live data is how a kill switch gets flipped against a picture from twenty
/// minutes ago. Mutations are disabled for as long as this is up.
class FleetOfflineBanner extends StatelessWidget {
  const FleetOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Sp.s4, Sp.s2, Sp.s4, 0),
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s3,
        vertical: Sp.s2h,
      ),
      decoration: SatBox.d(
        color: sc.warnSoft,
        borderRadius: SatR.a(12),
        border: SatB.all(color: sc.warn.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: sc.warn),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              'Tidak terhubung — data tersimpan, bisa sudah berubah. '
              'Perubahan dinonaktifkan sampai tersambung.',
              style: SatType.labelS(color: sc.warn),
            ),
          ),
        ],
      ),
    );
  }
}

/// Strips the `[code]` prefix Cloud Functions errors carry.
String fleetErrText(Object e) {
  final s = e.toString();
  return s.contains(']') ? s.split(']').last.trim() : s;
}

/// Hub-style header: small icon + kicker, then a big title. Matches the phone
/// Venue Hub. Used at the top of the Fleet console.
class FleetHeader extends StatelessWidget {
  final String kicker;
  final String title;
  final IconData icon;
  final Widget? trailing;

  /// Overrides the kicker's accent when the kicker is carrying a count that is
  /// itself the news — "3 PERLU TINDAKAN" in `urgent`. Null keeps the accent.
  final Color? kickerColor;
  const FleetHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.icon = Icons.travel_explore_rounded,
    this.trailing,
    this.kickerColor,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final kc = kickerColor ?? sc.accentText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: kc),
            const SizedBox(width: Sp.s1h),
            Expanded(child: Text(kicker, style: SatType.caption(color: kc))),
            ?trailing,
          ],
        ),
        const SizedBox(height: Sp.s1),
        Text(title, style: SatType.h2(color: sc.textHi)),
      ],
    );
  }
}

// `FleetPrimaryButton` lived here and inked itself with `sc.bg0` — the page
// ground — on the theory that whatever the page is, the fill is its opposite.
// True on the charcoal palettes and false on every light one: under Neon Terang
// `bg0` is bone, so a lime button carried a near-white label at 1.03:1 and read
// as an empty slab. `SatButton.primary` / `.danger` own that ink decision
// properly (ADR-0055), which is the whole argument against a local button.
