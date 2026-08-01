import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/services/firebase_admin_service.dart';
import 'package:satset/data/services/fleet_service.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/features/fleet/_fleet_widgets.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

/// Everything a super admin does to one venue, opened from a Fleet console
/// tile: its **access** (the kill switch), its **subscription**
/// (plan / billingStatus / paidUntil), its **accounts** (per-venue admins and
/// report-only owners — there is no fleet-wide roster), its identity
/// (name/address, cloud source of truth per ADR-0018), and delete.
///
/// Section order is the order the operator arrives in. Access first, because a
/// venue is opened either to cut it off or to check why it is cut off; then the
/// subscription, which is the recurring act; then the people; and only then the
/// name and address, which is bookkeeping. Identity used to lead, so the two
/// questions the screen exists to answer sat below a fold.
///
/// **Two commit models, split by consequence.** Access and account actions fire
/// immediately, each behind its own confirmation — a kill switch that waits for
/// a Save the operator might not press is a kill switch that does not work.
/// Identity and subscription are *fields*, so they stage and commit on Save,
/// which diffs each group and fires only the callables whose values changed:
/// `updateVenue` for name/address, `setVenueBilling` for the subscription.
///
/// The venue's live document is watched rather than trusted from the tile that
/// pushed it, so the access card shows the state as it is now — including a
/// change made from another device while this screen is open.
class VenueEditScreen extends ConsumerStatefulWidget {
  const VenueEditScreen({super.key, required this.venue});

  final Venue venue;

  @override
  ConsumerState<VenueEditScreen> createState() => _VenueEditScreenState();
}

class _VenueEditScreenState extends ConsumerState<VenueEditScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.venue.name,
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.venue.address,
  );

  late String _planKey = widget.venue.plan;
  late String _billingStatus = _normBilling(widget.venue.billingStatus);
  late DateTime? _paidUntil = widget.venue.paidUntil;

  bool _busy = false;

  static String _normBilling(String s) =>
      const {'trial', 'paid', 'overdue'}.contains(s) ? s : 'trial';

  FleetService get _svc => ref.read(fleetServiceProvider);

  /// Mutations are locked while Firestore serves the cache — see
  /// [fleetOfflineProvider]. The editor writes venues *and* credentials, so it
  /// gets the same lock the console has.
  bool get _offline => ref.read(fleetOfflineProvider);

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  String get _nameText => _name.text.trim();
  bool get _nameValid => _nameText.isNotEmpty;

  /// The venue as the fleet currently holds it, falling back to the snapshot
  /// this screen was pushed with while the stream warms (or after a delete).
  ///
  /// Everything that reads venue state goes through here rather than
  /// `widget.venue`. The pushed snapshot froze the instant the tile was tapped;
  /// diffing Save against it meant a billing change made from another device
  /// while this screen sat open was silently overwritten with the old value on
  /// the next Save.
  Venue get _live =>
      (ref.read(fleetVenuesProvider).valueOrNull ?? const <Venue>[]).firstWhere(
        (x) => x.id == widget.venue.id,
        orElse: () => widget.venue,
      );

  /// Runs a one-shot admin/venue mutation with the shared busy + toast cycle.
  /// Returns whether the mutation actually landed — callers that navigate on
  /// success need to know, and a caught-and-toasted error used to be
  /// indistinguishable from a clean run.
  Future<bool> _run(Future<void> Function() action, String okMsg) async {
    if (_busy) return false;
    if (_offline) {
      fleetToast(
        context,
        'Tidak terhubung — perubahan tidak dikirim.',
        error: true,
      );
      return false;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) fleetToast(context, okMsg);
      return true;
    } catch (e) {
      if (mounted) fleetToast(context, fleetErrText(e), error: true);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// True once a staged field differs from the venue this screen opened on.
  /// Drives the Save button, so "nothing to save" is legible before the tap
  /// rather than as a silent pop afterwards.
  bool get _dirty {
    final v = _live;
    return _nameText != v.name ||
        _address.text.trim() != v.address ||
        _planKey != v.plan ||
        _billingStatus != _normBilling(v.billingStatus) ||
        _paidUntil != v.paidUntil;
  }

  Future<void> _save() async {
    if (_busy || !_nameValid) return;
    if (_offline) {
      fleetToast(
        context,
        'Tidak terhubung — perubahan tidak dikirim.',
        error: true,
      );
      return;
    }
    final v = _live;

    final newName = _nameText;
    final newAddress = _address.text.trim();

    final nameChanged = newName != v.name;
    final addressChanged = newAddress != v.address;
    final planChanged = _planKey != v.plan;
    final billingStatusChanged =
        _billingStatus != _normBilling(v.billingStatus);
    final paidUntilChanged = _paidUntil != v.paidUntil;

    if (!nameChanged &&
        !addressChanged &&
        !planChanged &&
        !billingStatusChanged &&
        !paidUntilChanged) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _busy = true);
    try {
      if (nameChanged || addressChanged) {
        await _svc.updateVenue(
          v.id,
          name: nameChanged ? newName : null,
          address: addressChanged ? newAddress : null,
        );
      }
      if (planChanged || billingStatusChanged || paidUntilChanged) {
        await _svc.setVenueBilling(
          v.id,
          plan: planChanged ? _planKey : null,
          billingStatus: billingStatusChanged ? _billingStatus : null,
          paidUntil: paidUntilChanged ? _paidUntil : null,
          clearPaidUntil: paidUntilChanged && _paidUntil == null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      fleetToast(context, fleetErrText(e), error: true);
    }
  }

  Future<void> _pickPaidUntil() async {
    final now = SatClock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidUntil ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _paidUntil = picked);
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final v = widget.venue;
    // The live document, not the tile's snapshot: the access card is a control
    // as well as a readout, and a control that shows a stale state is how a
    // venue gets suspended twice and un-suspended never. Falls back to the
    // pushed snapshot while the stream is warming (or after a delete).
    final live = (ref.watch(fleetVenuesProvider).valueOrNull ?? const <Venue>[])
        .firstWhere((x) => x.id == v.id, orElse: () => v);
    // Live per-venue admin list — drives both the accounts sections and the
    // delete-venue guard (delete needs zero accounts).
    final admins = ref.watch(fleetAdminsProvider);
    final forVenue = (admins.valueOrNull ?? const <AdminProfile>[])
        .where((a) => a.venueId == v.id)
        .toList();
    final venueAdmins =
        forVenue.where((a) => a.role == AdminRole.admin).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    // Owners (read-only report viewers, ADR-0036) are listed separately and
    // also block venue delete — a venue with anyone attached can't be deleted.
    final venueOwners =
        forVenue.where((a) => a.role == AdminRole.owner).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: sc.bg0,
      appBar: AppBar(
        backgroundColor: sc.bg0,
        elevation: 0,
        iconTheme: IconThemeData(color: sc.textHi),
        // The venue's own name, not "Edit venue". This screen holds the kill
        // switch; which venue is about to go dark is not a detail to infer from
        // the field below it.
        title: Text(
          live.name.isEmpty ? '(tanpa nama)' : live.name,
          overflow: TextOverflow.ellipsis,
          style: SatType.h3(color: sc.textHi),
        ),
        actions: [
          SatButton.ghost(
            label: AppStrings.save,
            onTap: _busy || !_nameValid || !_dirty ? null : _save,
          ),
          const SizedBox(width: Sp.s2),
        ],
        bottom: _busy
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: sc.accentText,
                ),
              )
            : null,
      ),
      // Capped to the console's column so the push does not change the shape of
      // the page under the operator's thumb, and so a landscape tablet stops
      // stretching a two-field address form across a metre of glass.
      //
      // **Seams carry the grouping**, because six equally-spaced cards make a
      // kill switch and an address field peers. One beat (Sp.s3) inside a
      // concern, two (Sp.s6) between concerns, three (Sp.s9) before the
      // irreversible: Akses ‖ Langganan ‖ Admin · Pemilik ‖ Identitas ⦀ Bahaya.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: fleetColumnMax),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              fleetGutter,
              Sp.s3,
              fleetGutter,
              Sp.s12,
            ),
            children: [
              if (ref.watch(fleetOfflineProvider)) ...[
                const FleetOfflineBanner(),
                const SizedBox(height: Sp.s4),
              ],
              _accessCard(sc, live),
              const SizedBox(height: Sp.s6),
              _subscriptionCard(sc),
              const SizedBox(height: Sp.s6),
              _principalSection(
                sc,
                admins,
                venueAdmins,
                role: 'admin',
                title: 'Admin venue',
                tag: 'AKUN',
                addLabel: 'Tambah admin',
                emptyMsg: 'Belum ada admin untuk venue ini.',
              ),
              // Admins and owners are one concern read as one block — who is
              // attached to this venue — so they sit a single beat apart.
              const SizedBox(height: Sp.s3),
              _principalSection(
                sc,
                admins,
                venueOwners,
                role: 'owner',
                title: 'Pemilik',
                tag: 'LAPORAN',
                addLabel: 'Tambah pemilik',
                emptyMsg: 'Belum ada pemilik untuk venue ini.',
              ),
              const SizedBox(height: Sp.s6),
              SatCard.titled(
                title: 'Identitas',
                tag: 'DATA',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SatField.text(
                      controller: _name,
                      label: 'Nama venue',
                      hint: '',
                      onChanged: (_) => setState(() {}),
                      errorText: _nameValid ? null : 'Nama wajib diisi',
                    ),
                    const SizedBox(height: Sp.s3h),
                    SatField.text(
                      controller: _address,
                      label: 'Alamat',
                      hint: 'opsional',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.s9),
              _dangerZone(sc, [...venueAdmins, ...venueOwners]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Access ───────────────────────────────────────────────────────────────

  /// The kill switch, given a surface of its own. It used to live only in the
  /// console tile's `⋮`, which meant the screen you open to decide whether to
  /// cut a venue off could not cut it off — and nothing on it said what the
  /// current state actually does to the venue's staff.
  ///
  /// State first as a sentence, transitions second, weighted by consequence:
  /// activate is `success`, suspend is a plain fill because it is reversible,
  /// blocking is `danger`. Three identical buttons would make "pause them for
  /// an hour" and "lock them out until I say otherwise" the same gesture.
  Widget _accessCard(SatColors sc, Venue live) {
    final vis = fleetStatusVisual(
      sc,
      live.status,
      activeIcon: Icons.storefront_outlined,
    );
    final can = !_busy && !_offline;
    return SatCard.titled(
      title: 'Akses venue',
      tag: 'KENDALI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: SatBox.d(
                  color: vis.tint.withValues(alpha: 0.12),
                  borderRadius: SatR.a(14),
                ),
                child: Icon(vis.icon, size: 22, color: vis.tint),
              ),
              const SizedBox(width: Sp.s3h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vis.label, style: SatType.labelL(color: vis.tint)),
                    const SizedBox(height: Sp.s1),
                    Text(
                      _accessMeaning(live.status),
                      style: SatType.bodyS(color: sc.textMd),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s4),
          Wrap(
            spacing: Sp.s2,
            runSpacing: Sp.s2,
            children: [
              if (live.status != AdminStatus.active)
                SatButton.success(
                  label: 'Aktifkan',
                  icon: Icons.play_arrow_rounded,
                  size: SatButtonSize.sm,
                  onTap: can
                      ? () => _run(
                          () => _svc.setVenueStatus(live.id, AdminStatus.active),
                          '${live.name} diaktifkan',
                        )
                      : null,
                ),
              if (live.status != AdminStatus.suspended)
                SatButton.neutral(
                  label: 'Tangguhkan',
                  icon: Icons.pause_circle_outline,
                  size: SatButtonSize.sm,
                  onTap: can
                      ? () => _confirm(
                          'Tangguhkan ${live.name}?',
                          'Server venue mati sekarang juga dan semua staf '
                              'terputus — termasuk di tengah jam ramai.',
                          'Tangguhkan',
                          () => _run(
                            () => _svc.setVenueStatus(
                              live.id,
                              AdminStatus.suspended,
                            ),
                            '${live.name} ditangguhkan',
                          ),
                        )
                      : null,
                ),
              if (live.status != AdminStatus.banned)
                SatButton.danger(
                  label: 'Blokir',
                  icon: Icons.block,
                  size: SatButtonSize.sm,
                  onTap: can
                      ? () => _confirm(
                          'Blokir ${live.name}?',
                          'Server venue mati dan tetap terblokir sampai '
                              'diubah di sini.',
                          'Blokir',
                          () => _run(
                            () => _svc.setVenueStatus(
                              live.id,
                              AdminStatus.banned,
                            ),
                            '${live.name} diblokir',
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// What the status *does*, not what it is called. "TANGGUH" tells an operator
  /// nothing about whether the waiters can still take orders.
  String _accessMeaning(AdminStatus s) => switch (s) {
    AdminStatus.active =>
      'Server venue berjalan dan staf bisa masuk seperti biasa.',
    AdminStatus.suspended =>
      'Server venue mati. Staf tidak bisa masuk sampai diaktifkan lagi.',
    AdminStatus.banned =>
      'Venue terblokir. Server mati dan tetap terkunci sampai diubah di sini.',
    AdminStatus.unknown =>
      'Status tidak dikenali di cloud. Setel ulang dengan tombol di bawah.',
  };

  // ── Subscription ─────────────────────────────────────────────────────────

  /// Plan, term and flag in one place, with the term editable the way it is
  /// actually used. Extending a paid venue was a date picker: five taps to land
  /// on a day a year out, on the single most repeated act in the console. The
  /// quick terms compute from the later of today and the current expiry, so
  /// renewing early adds to what is left instead of throwing it away.
  Widget _subscriptionCard(SatColors sc) {
    final can = !_busy && !_offline;
    return SatCard.titled(
      title: 'Langganan',
      tag: 'TAGIHAN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fleetPlanDropdown(
            value: _planKey,
            onChanged: (x) => setState(() => _planKey = x),
          ),
          const SizedBox(height: Sp.s4),
          _paidUntilRow(sc),
          const SizedBox(height: Sp.s3),
          Wrap(
            spacing: Sp.s2,
            runSpacing: Sp.s2,
            children: [
              for (final (months, label) in const [
                (1, '+1 bulan'),
                (3, '+3 bulan'),
                (12, '+1 tahun'),
              ])
                SatButton.outline(
                  label: label,
                  size: SatButtonSize.sm,
                  onTap: can ? () => _extend(months) : null,
                ),
            ],
          ),
          const SizedBox(height: Sp.s4),
          SatDropdown<String>(
            value: _billingStatus,
            label: 'Status tagihan',
            options: const [
              SatOption('trial', 'trial'),
              SatOption('paid', 'paid'),
              SatOption('overdue', 'overdue'),
            ],
            onChanged: (x) =>
                setState(() => _billingStatus = x ?? _billingStatus),
          ),
        ],
      ),
    );
  }

  /// Extends the term and flips the flag with it. Keeping them separate is what
  /// produces the console's worst state — a venue reading `paid` with a date
  /// three weeks gone, which looks healthy on every tile and bills nobody — so
  /// the act that sets a future date is the act that says it is paid.
  void _extend(int months) {
    final now = SatClock.now();
    final p = _paidUntil;
    final base = (p != null && p.isAfter(now)) ? p : now;
    setState(() {
      _paidUntil = fleetAddMonths(base, months);
      _billingStatus = 'paid';
    });
  }

  // ── Accounts ─────────────────────────────────────────────────────────────

  Widget _principalSection(
    SatColors sc,
    AsyncValue<List<AdminProfile>> all,
    List<AdminProfile> rows, {
    required String role,
    required String title,
    required String tag,
    required String addLabel,
    required String emptyMsg,
  }) {
    final loading = all.isLoading && !all.hasValue;
    return SatCard.titled(
      title: title,
      tag: tag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (all.hasError) ...[
            Text(
              'Gagal memuat: ${fleetErrText(all.error!)}',
              style: SatType.bodyS(color: sc.urgent),
            ),
            const SizedBox(height: Sp.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: SatButton.outline(
                label: 'Coba lagi',
                icon: Icons.refresh,
                size: SatButtonSize.sm,
                onTap: () => ref.invalidate(fleetAdminsProvider),
              ),
            ),
          ]
          else if (loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.s5),
              child: Center(
                child: CircularProgressIndicator(color: sc.accentText),
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s3h),
              child: Text(emptyMsg, style: SatType.bodyM(color: sc.textLo)),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              _adminRow(sc, rows[i]),
              SizedBox(height: i == rows.length - 1 ? Sp.s3h : Sp.s2),
            ],
          // Adding follows the list rather than heading it: the operator reads
          // who is already on the venue before deciding to add another, and a
          // full-width primary above an empty list was the loudest thing on a
          // screen whose loudest thing should be the kill switch.
          Align(
            alignment: Alignment.centerLeft,
            child: SatButton.outline(
              label: addLabel,
              icon: Icons.person_add_alt_1,
              size: SatButtonSize.sm,
              onTap: _busy || _offline
                  ? null
                  : () => _createPrincipalDialog(role),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminRow(SatColors sc, AdminProfile a) {
    final vis = fleetStatusVisual(
      sc,
      a.status,
      activeIcon: Icons.person_outline_rounded,
    );
    return FleetTile(
      big: false,
      icon: vis.icon,
      tint: vis.tint,
      title: a.name.isEmpty ? '(tanpa nama)' : a.name,
      sub: a.email ?? a.uid,
      subMono: true,
      pills: [
        if (a.status != AdminStatus.active)
          fleetPill(sc, vis.label, vis.tint, vis.soft),
      ],
      trailing: fleetMenu(
        sc,
        enabled: !_busy && !_offline,
        tooltip: 'Tindakan akun',
        items: {
          if (a.status != AdminStatus.active) 'activate': 'Aktifkan',
          if (a.status != AdminStatus.suspended) 'suspend': 'Tangguhkan',
          if (a.status != AdminStatus.banned) 'ban': 'Blokir',
          if (a.email != null) 'reset': 'Reset password',
          'delete': 'Hapus',
        },
        dangerKeys: const {'ban', 'delete'},
        onSelected: (k) => _onAdminAction(a, k),
      ),
    );
  }

  void _onAdminAction(AdminProfile a, String k) {
    switch (k) {
      case 'activate':
        _run(
          () => _svc.setAdminStatus(a.uid, AdminStatus.active),
          '${a.name} diaktifkan',
        );
      case 'suspend':
        _run(
          () => _svc.setAdminStatus(a.uid, AdminStatus.suspended),
          '${a.name} ditangguhkan',
        );
      case 'ban':
        _run(
          () => _svc.setAdminStatus(a.uid, AdminStatus.banned),
          '${a.name} diblokir',
        );
      case 'reset':
        _resetPassword(a);
      case 'delete':
        _confirm(
          'Hapus ${a.name}?',
          'Akun login & datanya dihapus permanen. '
              '${a.email ?? a.uid} tidak bisa masuk lagi.',
          'Hapus',
          () => _run(() => _svc.deleteAdmin(a.uid), '${a.name} dihapus'),
        );
    }
  }

  // ── Temporary password ─────────────────────────────────────────────────────

  /// Mints a temporary password and shows it once.
  ///
  /// This action used to call `generatePasswordResetLink` and throw the link
  /// away — the operator got a toast, the admin got nothing, and there is no
  /// mail sender in this project to have sent it. What the operator actually
  /// does is phone the venue, so the act is now a code to read out. See
  /// ADR-0075.
  Future<void> _resetPassword(AdminProfile a) async {
    if (_busy) return;
    if (_offline) {
      fleetToast(
        context,
        'Tidak terhubung — perubahan tidak dikirim.',
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    String? otp;
    try {
      otp = await _svc.resetAdminPassword(a.uid);
    } catch (e) {
      if (mounted) fleetToast(context, fleetErrText(e), error: true);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || otp == null || otp.isEmpty) return;
    await _showOtpDialog(a, otp);
  }

  /// The code, once. There is no way back to it — the digits exist only in this
  /// dialog and in the account itself, so the copy says so rather than letting
  /// an operator discover it by closing the sheet too early.
  Future<void> _showOtpDialog(AdminProfile a, String otp) {
    final sc = context.sat;
    final pretty = otp.length == 8
        ? '${otp.substring(0, 4)} ${otp.substring(4)}'
        : otp;
    return showSatDialog<void>(
      context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sc.bg1,
        title: Text(
          AppStrings.tempPasswordIssuedTitle,
          style: SatType.h3(color: sc.textHi),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.email ?? a.name,
              style: SatType.monoS(color: sc.textMd),
            ),
            const SizedBox(height: Sp.s4),
            // Sized up and given its own surface because this is dictated down a
            // phone line in a loud room — the operator reads it off the glass
            // once and must not misread a digit.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: Sp.s4),
              decoration: SatBox.d(
                color: sc.bg2,
                border: SatB.all(color: sc.border0),
                borderRadius: SatR.md,
              ),
              child: Text(
                pretty,
                textAlign: TextAlign.center,
                style: SatType.monoDisplay(color: sc.textHi),
              ),
            ),
            const SizedBox(height: Sp.s3),
            Text(
              AppStrings.tempPasswordIssuedHint,
              style: SatType.bodyS(color: sc.textMd),
            ),
            const SizedBox(height: Sp.s2),
            Text(
              AppStrings.tempPasswordIssuedOnce,
              style: SatType.bodyS(color: sc.warn),
            ),
          ],
        ),
        actions: [
          SatButton.ghost(
            label: 'Salin',
            icon: Icons.copy_rounded,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: otp));
              if (ctx.mounted) fleetToast(ctx, 'Kode disalin');
            },
          ),
          SatButton.outline(
            label: 'Kirim WA',
            icon: Icons.chat_outlined,
            // No recipient: the fleet does not store venue phone numbers, so
            // this opens WhatsApp's own contact picker with the message ready.
            onTap: () => launchUrl(
              Uri.parse(
                'https://wa.me/?text='
                '${Uri.encodeComponent(AppStrings.tempPasswordShareMessage(pretty))}',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          SatButton.primary(
            label: AppStrings.close,
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  /// Three required fields and one exit: the old version validated *after* the
  /// dialog popped, so a forgotten password closed the sheet and created
  /// nothing, with no message. Validation is now inside, and the password is
  /// masked — this gets typed on a tablet held in someone else's dining room.
  Future<void> _createPrincipalDialog(String role) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final pw = TextEditingController();
    var pwVisible = false;
    final sc = context.sat;
    final roleLabel = role == 'owner' ? 'pemilik' : 'admin';
    try {
      final ok = await showSatDialog<bool>(
        context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) {
            final emailText = email.text.trim();
            final emailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                .hasMatch(emailText);
            final pwText = pw.text;
            final valid =
                name.text.trim().isNotEmpty && emailValid && pwText.length >= 6;
            return AlertDialog(
              backgroundColor: sc.bg1,
              title: Text(
                'Tambah $roleLabel · ${widget.venue.name}',
                style: SatType.h3(color: sc.textHi),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SatField.text(
                    controller: name,
                    label: 'Nama',
                    hint: '',
                    autofocus: true,
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: Sp.s3),
                  SatField.text(
                    controller: email,
                    label: 'Email',
                    hint: '',
                    onChanged: (_) => setLocal(() {}),
                    errorText: emailText.isEmpty || emailValid
                        ? null
                        : 'Format email tidak valid',
                  ),
                  const SizedBox(height: Sp.s3),
                  SatField.password(
                    controller: pw,
                    label: 'Password awal',
                    hint: '',
                    visible: pwVisible,
                    onToggle: () => setLocal(() => pwVisible = !pwVisible),
                    onChanged: (_) => setLocal(() {}),
                    errorText: pwText.isEmpty || pwText.length >= 6
                        ? null
                        : 'Minimal 6 karakter',
                  ),
                ],
              ),
              actions: [
                SatButton.ghost(
                  label: AppStrings.cancel,
                  onTap: () => Navigator.pop(ctx, false),
                ),
                SatButton.primary(
                  label: AppStrings.save,
                  onTap: valid ? () => Navigator.pop(ctx, true) : null,
                ),
              ],
            );
          },
        ),
      );
      if (ok != true) return;
      await _run(
        () => _svc.createAdmin(
          email: email.text,
          password: pw.text,
          name: name.text,
          venueId: widget.venue.id,
          role: role,
        ),
        '${role == 'owner' ? 'Pemilik' : 'Admin'} dibuat',
      );
    } finally {
      name.dispose();
      email.dispose();
      pw.dispose();
    }
  }

  // ── Danger zone ────────────────────────────────────────────────────────────

  /// Not a [SatCard]: the whole point is that it does not look like the five
  /// surfaces above it.
  Widget _dangerZone(SatColors sc, List<AdminProfile> admins) {
    final blocked = admins.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(Sp.s4),
      decoration: SatBox.d(
        color: sc.urgentSoft,
        border: SatB.all(color: sc.urgent),
        borderRadius: SatR.a(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ZONA BAHAYA', style: SatType.caption(color: sc.urgent)),
          const SizedBox(height: Sp.s2h),
          Text(
            blocked
                ? 'Hapus semua akun venue ini dulu sebelum menghapus venue. '
                      'Untuk sekadar memutus akses, pakai Tangguhkan di atas.'
                : 'Menghapus venue tidak dapat dibatalkan. Untuk sekadar '
                      'memutus akses, pakai Tangguhkan di atas.',
            style: SatType.bodyM(color: sc.textMd),
          ),
          const SizedBox(height: Sp.s3h),
          SatButton.danger(
            label: 'Hapus venue',
            icon: Icons.delete_outline,
            onTap: blocked || _busy || _offline ? null : _confirmDeleteVenue,
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVenue() {
    final v = widget.venue;
    _confirm(
      'Hapus ${v.name}?',
      'Venue dihapus permanen dari fleet. Tidak bisa dibatalkan.',
      'Hapus venue',
      () async {
        // Pops only on a delete that actually landed. It used to pop
        // unconditionally, so a `failed-precondition` (an admin added between
        // opening this screen and confirming) or an offline block closed the
        // editor as though the venue were gone — and the console behind it
        // still listed it.
        final ok = await _run(
          () => _svc.deleteVenue(v.id),
          '${v.name} dihapus',
        );
        if (ok && mounted) Navigator.of(context).pop();
      },
    );
  }

  // ── Small pieces ───────────────────────────────────────────────────────────

  /// [confirmLabel] names the act rather than saying "Lanjut" — the difference
  /// between confirming a suspend and confirming a permanent delete should be
  /// legible on the button, not only in the title.
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
            label: AppStrings.cancel,
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

  Widget _paidUntilRow(SatColors sc) {
    final now = SatClock.now();
    final p = _paidUntil;
    final expired = p != null && p.isBefore(now);
    final label = p == null ? 'Belum diatur' : formatShortDateId(p);
    // The date alone makes the operator do the arithmetic. "12 Agu" is not an
    // answer to "do I invoice this venue today"; "18 hari lagi" is.
    final remain = p == null
        ? null
        : expired
        ? 'Sudah lewat'
        : '${p.difference(now).inDays} hari lagi';
    final tint = p == null
        ? sc.textMd
        : expired
        ? sc.urgent
        : (p.difference(now) <= fleetRenewWarn ? sc.warn : sc.textMd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A *field*, not a surface: `bg1` on the card's `bg2` with its own
        // radius made this a card inside a card, sitting between two dropdowns
        // that fill with `bg2` at `SatR.md`. It is the same kind of thing they
        // are — a labelled value you can change — so it wears their chrome.
        Container(
          padding: const EdgeInsets.fromLTRB(Sp.s3h, Sp.s2, Sp.s2, Sp.s2),
          decoration: SatBox.d(
            color: sc.bg2,
            border: SatB.all(color: expired ? sc.urgent : sc.border0),
            borderRadius: SatR.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berlaku sampai',
                      style: SatType.bodyS(color: sc.textMd),
                    ),
                    const SizedBox(height: Sp.sHair),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: SatType.labelL(
                              color: expired ? sc.urgent : sc.textHi,
                            ),
                          ),
                        ),
                        if (remain != null) ...[
                          const SizedBox(width: Sp.s2),
                          Text(
                            remain,
                            style: SatType.caption(color: tint),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (p != null)
                SatIconButton.plain(
                  icon: Icons.clear,
                  tooltip: 'Hapus tanggal',
                  onTap: () => setState(() => _paidUntil = null),
                ),
              SatButton.ghost(label: 'Pilih', onTap: _pickPaidUntil),
            ],
          ),
        ),
        // The flag and the date can disagree, and when they do the flag wins
        // everywhere else in the app — a venue reading `paid` with a date three
        // weeks gone looks fine on the console tile and bills nobody.
        if (_billingMismatch case final warning?) ...[
          const SizedBox(height: Sp.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: sc.warn),
              const SizedBox(width: Sp.s2),
              Expanded(
                child: Text(warning, style: SatType.bodyS(color: sc.warn)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Reads the billing flag against the date, in the direction that costs
  /// money: `paid` past its date, and `paid` with no date at all.
  String? get _billingMismatch {
    if (_billingStatus != 'paid') return null;
    final p = _paidUntil;
    if (p == null) return 'Ditandai lunas tanpa tanggal berlaku.';
    if (p.isBefore(SatClock.now())) {
      return 'Ditandai lunas tapi masa berlakunya sudah lewat — '
          'perpanjang tanggalnya atau ubah status ke overdue.';
    }
    return null;
  }
}
