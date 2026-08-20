import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/data/models/self_order_dto.dart';
import 'package:satset/data/repositories/self_order_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_tabs.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/features/printing/printer_picker.dart';
import '_common.dart';

/// **[[Pesan mandiri]]** — how the venue *configures* guest self-order
/// (ADR-0106): codes to print, what a guest may see, what the rules are.
///
/// The queue it feeds lives on its own nav destination and is a different
/// screen with a different capability ([[SelfOrderScreen]], `takeOrder`).
/// This one is `editSettings` and reached from the Venue hub, because
/// everything on it is an owner's decision the floor never makes mid-shift.
///
/// Tablet only, like `/audit` and `/kas`: the three tabs are read against each
/// other — a table's QR against whether that table is on, an item's visibility
/// against the rules that gate it — and a phone can hold one at a time.
class SelfOrderAdminScreen extends ConsumerStatefulWidget {
  const SelfOrderAdminScreen({super.key});

  @override
  ConsumerState<SelfOrderAdminScreen> createState() =>
      _SelfOrderAdminScreenState();
}

class _SelfOrderAdminScreenState extends ConsumerState<SelfOrderAdminScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tablet = context.layout.useTabletShell;
    final st = ref.watch(selfOrderProvider);

    if (!tablet) {
      return Center(
        child: SatEmpty(
          icon: Icons.tablet_mac_outlined,
          title: l10n.soAdminTitle,
          body: l10n.soTabletOnly,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEmbeddedStrip(
          title: l10n.soAdminTitle,
          sub: l10n.soAdminSub,
          trailing: SatTabs(
            tabs: [
              SatTab(label: l10n.soTabQr),
              SatTab(label: l10n.soTabMenu),
              SatTab(label: l10n.soTabRules),
            ],
            selected: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(
          child: switch (_tab) {
            1 => _MenuTab(state: st),
            2 => _RulesTab(state: st),
            _ => _QrTab(state: st),
          },
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// tab 1 — QR & tables
// ---------------------------------------------------------------------------

class _QrTab extends ConsumerWidget {
  final SelfOrderState state;
  const _QrTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sc = context.sat;
    return ListView(
      padding: const EdgeInsets.all(Sp.s4),
      children: [
        SatCard.titled(
          title: l10n.soTableTitle,
          tag: l10n.soTabQr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.soTableSub, style: SatType.bodyM(color: sc.textMd)),
              const SizedBox(height: Sp.s3),
              Row(
                children: [
                  SatButton.outline(
                    label: l10n.soPrintAll,
                    icon: Icons.print_rounded,
                    onTap: () => _printAll(context, ref),
                  ),
                  const SizedBox(width: Sp.s2),
                  SatButton.outline(
                    label: l10n.soRotate,
                    icon: Icons.autorenew_rounded,
                    onTap: () => _rotate(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
        // The counter's card, above the tables and only while the switch is
        // on (ADR-0109). One QR for the whole shop: each scan opens its own
        // session and each accepted order becomes its own Bawa pulang bill, so
        // two strangers in the same queue never land on one tab.
        if (state.counterCode.isNotEmpty) ...[
          const SizedBox(height: Sp.s4),
          _CounterCodeCard(url: guestUrlFor(state, state.counterCode)),
        ],
        const SizedBox(height: Sp.s4),
        for (final t in state.tables)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.s3),
            child: _TableCodeCard(table: t, url: guestUrlFor(state, t.code)),
          ),
      ],
    );
  }

  /// Every table that is actually serving self-order, in one job. A table
  /// switched off has a code that resolves to nothing, so printing its card
  /// would put a dead QR on a live table.
  Future<void> _printAll(BuildContext context, WidgetRef ref) async {
    final cards = <({String label, String url})>[
      if (guestUrlFor(state, state.counterCode) case final u?)
        (label: context.l10n.soCounterLabel, url: u),
      for (final t in state.tables)
        if (t.enabled)
          if (guestUrlFor(state, t.code) case final u?)
            (label: t.label ?? t.id, url: u),
    ];
    await printAllTableQr(context: context, ref: ref, cards: cards);
  }

  Future<void> _rotate(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showSatDialog<bool>(
      context,
      builder: (c) => AlertDialog(
        title: Text(l10n.soRotateConfirmTitle),
        content: Text(l10n.soRotateConfirmBody),
        actions: [
          SatButton.ghost(
            label: l10n.cancel,
            onTap: () => Navigator.of(c).pop(false),
          ),
          SatButton.danger(
            label: l10n.soRotate,
            onTap: () => Navigator.of(c).pop(true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(selfOrderProvider.notifier).rotateCodes();
  }
}

/// The counter's QR. Deliberately not a [_TableCodeCard] with a different
/// label: it has no room, no seat count and no per-table switch to draw, and
/// the printed card wants the shop's name where a table's wants its number.
class _CounterCodeCard extends ConsumerWidget {
  final String? url;

  const _CounterCodeCard({this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sc = context.sat;
    return SatCard.plain(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (url != null)
            Container(
              padding: const EdgeInsets.all(Sp.s2),
              decoration: SatBox.d(
                // Paper tokens, not the theme ramp — same reason as the table
                // card: a QR is scanned off a screen or off paper, and a dark
                // one on a dark ground does not resolve.
                color: satPaperGround,
                borderRadius: SatR.a(8),
              ),
              child: QrImageView(
                data: url!,
                version: QrVersions.auto,
                size: 96,
                padding: EdgeInsets.zero,
                backgroundColor: satPaperGround,
              ),
            ),
          const SizedBox(width: Sp.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.soCounterLabel,
                  style: SatType.labelL(color: sc.textHi),
                ),
                const SizedBox(height: Sp.sHair),
                Text(
                  l10n.soCounterSub,
                  style: SatType.bodyS(color: sc.textLo),
                ),
                const SizedBox(height: Sp.s3),
                if (url == null)
                  Text(
                    l10n.soNoHost,
                    style: SatType.bodyS(color: sc.warn),
                  )
                else
                  SatButton.outline(
                    label: l10n.soPrint,
                    icon: Icons.print_rounded,
                    size: SatButtonSize.sm,
                    onTap: () => printTableQr(
                      context: context,
                      ref: ref,
                      tableLabel: l10n.soCounterLabel,
                      url: url!,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCodeCard extends ConsumerWidget {
  final GuestTableDto table;
  final String? url;
  const _TableCodeCard({required this.table, this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l10n = context.l10n;
    return SatCard.plain(
      padding: const EdgeInsets.all(Sp.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (url != null)
            Container(
              padding: const EdgeInsets.all(Sp.s2),
              // Paper tokens, not the theme ramp: a QR is scanned, and a dark
              // module on a dark surface is not scannable on either theme.
              // Same pair the receipt preview prints onto.
              decoration: SatBox.d(
                color: satPaperGround,
                borderRadius: SatR.a(10),
              ),
              child: QrImageView(
                data: url!,
                version: QrVersions.auto,
                size: 96,
                padding: EdgeInsets.zero,
                backgroundColor: satPaperGround,
              ),
            ),
          const SizedBox(width: Sp.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.soQrFor(table.label ?? table.id),
                  style: SatType.labelL(color: sc.textHi),
                ),
                if (table.zoneName.isNotEmpty)
                  Text(
                    l10n.soTableMeta(table.zoneName, table.seats),
                    style: SatType.bodyS(color: sc.textMd),
                  ),
                const SizedBox(height: Sp.s1),
                Text(
                  url ?? l10n.soNoHost,
                  style: SatType.monoS(color: sc.textLo),
                ),
                const SizedBox(height: Sp.s3),
                Row(
                  children: [
                    SatToggle(
                      value: table.enabled,
                      semanticLabel: l10n.soTableOn,
                      onChanged: (v) => ref
                          .read(selfOrderProvider.notifier)
                          .setTableEnabled(table.id, v),
                    ),
                    const SizedBox(width: Sp.s2),
                    Expanded(
                      child: Text(
                        l10n.soTableOn,
                        style: SatType.bodyS(color: sc.textMd),
                      ),
                    ),
                    if (url != null)
                      SatButton.outline(
                        label: l10n.soPrint,
                        icon: Icons.print_rounded,
                        size: SatButtonSize.sm,
                        onTap: () => printTableQr(
                          context: context,
                          ref: ref,
                          tableLabel: table.label ?? table.id,
                          url: url!,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// tab 2 — the guest menu
// ---------------------------------------------------------------------------

class _MenuTab extends ConsumerWidget {
  final SelfOrderState state;
  const _MenuTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sc = context.sat;
    final n = ref.read(selfOrderProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(Sp.s4),
      children: [
        Text(l10n.soMenuSub, style: SatType.bodyM(color: sc.textMd)),
        const SizedBox(height: Sp.s1),
        Text(l10n.soMenuAlcoholHint, style: SatType.bodyS(color: sc.textLo)),
        const SizedBox(height: Sp.s4),
        // Grouped by category, because the [[Jam tayang]] is set per category
        // and a control belongs beside the things it governs. A category the
        // payload never mentioned (it holds nothing) draws nothing.
        for (final c in state.categories) ...[
          _CategoryHeader(category: c, notifier: n),
          const SizedBox(height: Sp.s2),
          for (final i in state.menu.where((i) => i.categoryId == c.id))
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s2),
              child: _GuestMenuRow(item: i, notifier: n),
            ),
          const SizedBox(height: Sp.s4),
        ],
      ],
    );
  }
}

/// A category heading on the [[Menu tamu]] tab, carrying the one control that
/// governs every row under it: its [[Jam tayang]].
///
/// The window shuts the items rather than hiding them — a guest who cannot
/// find breakfast at all assumes it was discontinued, one who sees it greyed
/// knows to come back tomorrow — so this is a *sold out* control that happens
/// to run on a clock, not a visibility one.
class _CategoryHeader extends StatelessWidget {
  final GuestCategoryDto category;
  final SelfOrderRepository notifier;
  const _CategoryHeader({required this.category, required this.notifier});

  static String _hhmm(int min) =>
      '${(min ~/ 60).toString().padLeft(2, '0')}:'
      '${(min % 60).toString().padLeft(2, '0')}';

  Future<void> _edit(BuildContext context) async {
    final from = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (category.fromMin ?? 360) ~/ 60,
        minute: (category.fromMin ?? 360) % 60,
      ),
    );
    if (from == null || !context.mounted) return;
    final to = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (category.toMin ?? 660) ~/ 60,
        minute: (category.toMin ?? 660) % 60,
      ),
    );
    if (to == null) return;
    final f = from.hour * 60 + from.minute;
    final t = to.hour * 60 + to.minute;
    // An equal pair has no meaning the server will take — it would be a
    // category that is never on, and "never" is what hiding the items is for.
    if (f == t) return;
    await notifier.setCategoryWindow(category.id, fromMin: f, toMin: t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sc = context.sat;
    final on = category.fromMin != null && category.toMin != null;
    return Row(
      children: [
        Expanded(
          child: Text(category.name, style: SatType.labelL(color: sc.textHi)),
        ),
        if (on) ...[
          SatButton.ghost(
            label: l10n.soWindowClear,
            size: SatButtonSize.sm,
            onTap: () => notifier.setCategoryWindow(category.id),
          ),
          const SizedBox(width: Sp.s2),
        ],
        SatButton.outline(
          label: on
              ? '${_hhmm(category.fromMin!)}–${_hhmm(category.toMin!)}'
              : l10n.soWindowAlways,
          icon: Icons.schedule,
          size: SatButtonSize.sm,
          onTap: () => _edit(context),
        ),
      ],
    );
  }
}

/// One [[Menu tamu]] row. Two things are being decided here and they are not
/// the same decision: whether a guest may *see* the item (`visible`,
/// `featured`), and whether they may *have* it right now (`stockOverride`) —
/// so the stock control is a three-way on its own line rather than a fourth
/// chip in the row above it.
class _GuestMenuRow extends StatelessWidget {
  final GuestMenuItemDto item;
  final SelfOrderRepository notifier;
  const _GuestMenuRow({required this.item, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sc = context.sat;
    final overridden = item.stockOverride != 'auto';
    return SatCard.plain(
      padding: const EdgeInsets.all(Sp.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: SatType.bodyM(color: sc.textHi)),
                    if (item.description.isNotEmpty)
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.bodyS(color: sc.textLo),
                      ),
                    Text(
                      formatIDR(item.basePrice),
                      style: SatType.monoS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
              SatChip.select(
                label: l10n.soItemFeatured,
                selected: item.featured,
                onTap: () =>
                    notifier.setItemGuest(item.id, featured: !item.featured),
              ),
              const SizedBox(width: Sp.s2),
              // A toggle, not a one-way button: the list carries the hidden
              // items too, because the control that hides an item is the only
              // one that can bring it back.
              SatChip.select(
                label: l10n.soItemVisible,
                selected: item.visible,
                onTap: () =>
                    notifier.setItemGuest(item.id, visible: !item.visible),
              ),
              const SizedBox(width: Sp.s2),
              SatChip.select(
                label: l10n.soAlcohol,
                selected: item.alcohol,
                onTap: () =>
                    notifier.setItemGuest(item.id, alcohol: !item.alcohol),
              ),
            ],
          ),
          const SizedBox(height: Sp.s3),
          Row(
            children: [
              for (final o in const [
                ('auto', 0),
                ('forceIn', 1),
                ('forceOut', 2),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: Sp.s2),
                  child: SatChip.select(
                    label: switch (o.$2) {
                      1 => l10n.soStockIn,
                      2 => l10n.soStockOut,
                      _ => l10n.soStockAuto,
                    },
                    selected: item.stockOverride == o.$1,
                    // Tapping the held-down one lets go. Without it the only
                    // way back to the inventory is to wait for midnight.
                    onTap: () => notifier.setItemGuest(
                      item.id,
                      stockOverride: item.stockOverride == o.$1 ? 'auto' : o.$1,
                    ),
                  ),
                ),
              const Spacer(),
              if (overridden)
                Padding(
                  padding: const EdgeInsets.only(right: Sp.s2),
                  child: SatChip.tag(
                    label: l10n.soOverrideManual,
                    hue: SatChipHue.warn,
                  ),
                ),
              // The **effective** answer, which is the only one the guest
              // sees: derived server-side from the inventory and whatever
              // override is still in date, never recomputed here.
              Text(
                item.soldOut ? l10n.soEffectiveOut : l10n.soEffectiveIn,
                style: SatType.bodyS(
                  color: item.soldOut ? sc.urgent : sc.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// tab 3 — the rules
// ---------------------------------------------------------------------------

class _RulesTab extends ConsumerWidget {
  final SelfOrderState state;
  const _RulesTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    final n = ref.read(venueSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(Sp.s4),
      children: [
        // The master switch lives here and only here (ADR-0106). It is an
        // `editSettings` write, and the queue it interrupts is a waiter's
        // screen — a lone admin control sitting on it was the thing the split
        // set out to remove. The service window reads next to it because
        // "off" and "outside hours" are the two ways a guest is turned away.
        SatCard.titled(
          title: l10n.soRuleMaster,
          tag: l10n.soTabRules,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SatToggle(
                    value: s.guestOrderingEnabled,
                    semanticLabel: l10n.soRuleMaster,
                    onChanged: (v) => n.patch(guestOrderingEnabled: v),
                  ),
                  const SizedBox(width: Sp.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.soRuleMasterSub,
                          style: SatType.bodyM(color: sc.textMd),
                        ),
                        Text(
                          _hoursLine(l10n, s.guestHoursStartMin, s.guestHoursEndMin),
                          style: SatType.bodyS(color: sc.textLo),
                        ),
                      ],
                    ),
                  ),
                  if (guestPreviewUrl(state) != null)
                    SatButton.ghost(
                      label: l10n.soGuestPreview,
                      icon: Icons.open_in_new_rounded,
                      size: SatButtonSize.sm,
                      onTap: () => _openGuestPage(context, state),
                    ),
                ],
              ),
              const SizedBox(height: Sp.s2),
              Text(
                l10n.soRestartNeeded,
                style: SatType.bodyS(color: sc.warn),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.s4),
        SatCard.titled(
          title: l10n.soTabRules,
          tag: l10n.soTitle,
          child: Column(
            children: [
              AdminRow(
                label: l10n.soRuleNote,
                value: Row(
                  children: [
                    SatToggle(
                      value: s.guestNoteEnabled,
                      semanticLabel: l10n.soRuleNote,
                      onChanged: (v) => n.patch(guestNoteEnabled: v),
                    ),
                    const SizedBox(width: Sp.s3),
                    Expanded(
                      child: Text(
                        l10n.soRuleNoteSub,
                        style: SatType.bodyS(color: sc.textLo),
                      ),
                    ),
                  ],
                ),
              ),
              AdminRow(
                label: l10n.soRuleMaxItems,
                value: _NumberBox(
                  value: s.guestMaxItems,
                  onChanged: (v) => n.patch(guestMaxItems: v),
                ),
              ),
              AdminRow(
                label: l10n.soRuleSession,
                value: _NumberBox(
                  value: s.guestSessionHours,
                  onChanged: (v) => n.patch(guestSessionHours: v),
                ),
              ),
              AdminRow(
                last: true,
                label: l10n.soRuleHours,
                value: Row(
                  children: [
                    Expanded(
                      child: _NumberBox(
                        value: s.guestHoursStartMin,
                        onChanged: (v) => n.patch(guestHoursStartMin: v),
                      ),
                    ),
                    const SizedBox(width: Sp.s2),
                    Expanded(
                      child: _NumberBox(
                        value: s.guestHoursEndMin,
                        onChanged: (v) => n.patch(guestHoursEndMin: v),
                      ),
                    ),
                    const SizedBox(width: Sp.s3),
                    Expanded(
                      child: Text(
                        l10n.soRuleHoursSub,
                        style: SatType.bodyS(color: sc.textLo),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The address a printed QR points at: the LAN host **the server reported**,
/// on the cleartext guest port.
///
/// Not the host this client is paired to. On the server device those are the
/// same screen, and that pairing is loopback — building the URL from it
/// prints `http://127.0.0.1:8080/...`, which on a guest's phone resolves to
/// the guest's phone. Null (no LAN) renders `soNoHost` rather than a QR
/// nobody can use.
String? guestUrlFor(SelfOrderState st, String code) {
  final host = st.host;
  if (host == null || host.isEmpty || code.isEmpty) return null;
  return 'http://$host:${st.guestPort}/t/$code';
}

/// What the preview opens: a **table's** page, never the plane's root.
///
/// The guest plane serves `/t/<code>` and `/guest/*` and nothing else — the
/// table code is the credential, so a bare `/` is a 404 by design and opening
/// it showed the owner an error page for a working feature. First serving
/// table with a code; null when the venue has none, which is the same "nothing
/// to show" the QR cards already render.
String? guestPreviewUrl(SelfOrderState st) {
  // The counter first, when there is one: a [[Kedai]] may have no serving
  // tables at all, and its owner previewing "the guest page" means the page
  // their guests actually scan.
  if (guestUrlFor(st, st.counterCode) case final u?) return u;
  for (final t in st.tables) {
    if (!t.enabled) continue;
    if (guestUrlFor(st, t.code) case final u?) return u;
  }
  return null;
}

/// The guest page as the guest sees it, on the address the QR carries — not
/// the loopback this tablet is paired over. Opened in the system browser
/// because a preview inside the app is a preview of the app.
Future<void> _openGuestPage(BuildContext context, SelfOrderState st) async {
  final url = guestPreviewUrl(st);
  final ok = url != null &&
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.soNoHost)));
  }
}

/// A settings number, committed on submit rather than per keystroke — every
/// change here is a `PATCH`, and a three-digit field would otherwise send three.
class _NumberBox extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _NumberBox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SatField.number(
    controller: TextEditingController(text: '$value'),
    hint: '$value',
    onSubmitted: (raw) {
      final v = int.tryParse(raw.trim());
      if (v != null && v != value) onChanged(v);
    },
  );
}

/// `660` → `11:00`. The rules tab stores service hours as minutes past
/// midnight because that is what compares cleanly across a wrap past
/// midnight; a person reads a clock.
String _clock(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Equal start and end means no window at all — the same rule
/// `withinServiceHours` holds server-side, said in words.
String _hoursLine(AppL10n l10n, int startMin, int endMin) => startMin == endMin
    ? l10n.soHeroHoursOpen
    : l10n.soHeroHours('${_clock(startMin)}–${_clock(endMin)}');
