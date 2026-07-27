import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/state/theme_view_model.dart';

import 'book_entries.dart';

/// Debug-only widget gallery: every widget in `lib/ui/core/widgets/`, each
/// rendered in all of its states against canned data.
///
/// Reachable at `/book`, which only exists under `kDebugMode` and is exempt
/// from the router's pair gate — the whole point is browsing the design system
/// on a device that has never been paired.
///
/// Deliberately obeys `test/design_tokens_test.dart` like any other screen: a
/// gallery that documents the token system while ignoring it would be lying.
class BookScreen extends ConsumerStatefulWidget {
  const BookScreen({super.key});

  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final q = _query.trim().toLowerCase();
    final entries = bookEntries()
        .where((e) => q.isEmpty || e.name.toLowerCase().contains(q))
        .toList();

    final grouped = <String, List<BookEntry>>{};
    for (final e in entries) {
      (grouped[e.group] ??= []).add(e);
    }

    final rows = <Widget>[];
    grouped.forEach((group, items) {
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.s4, Sp.s5, Sp.s4, Sp.s2),
          child: Text(
            group.toUpperCase(),
            style: SatType.mono(
              size: 11,
              weight: FontWeight.w600,
              letterSpacing: 1.2,
              color: sc.textDim,
            ),
          ),
        ),
      );
      for (final e in items) {
        rows.add(
          ListTile(
            title: Text(
              e.name,
              style: SatType.sans(size: 15, color: sc.textHi),
            ),
            subtitle: Text(
              e.states.isEmpty
                  ? 'not rendered — see note'
                  : '${e.states.length} state${e.states.length == 1 ? '' : 's'}',
              style: SatType.sans(size: 12, color: sc.textDim),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: sc.textDim),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => _BookStage(entry: e)),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Column(
          children: [
            _BookBar(
              title: 'Widget book',
              subtitle: '${entries.length} entries · debug only',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: SatType.sans(size: 14, color: sc.textHi),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'search',
                  hintStyle: SatType.sans(size: 14, color: sc.textDim),
                  prefixIcon: Icon(Icons.search_rounded, color: sc.textDim),
                  filled: true,
                  fillColor: sc.bg1,
                  border: OutlineInputBorder(
                    borderRadius: SatR.a(10),
                    borderSide: BorderSide(color: sc.border1),
                  ),
                ),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(
                        'nothing matches "$_query"',
                        style: SatType.sans(size: 13, color: sc.textDim),
                      ),
                    )
                  : ListView(children: rows),
            ),
          ],
        ),
      ),
    );
  }
}

/// One widget, every state, stacked and captioned.
class _BookStage extends ConsumerStatefulWidget {
  final BookEntry entry;
  const _BookStage({required this.entry});

  @override
  ConsumerState<_BookStage> createState() => _BookStageState();
}

class _BookStageState extends ConsumerState<_BookStage> {
  /// Bumped by the replay action to remount the whole stage, which re-fires
  /// every mount-triggered entrance at once.
  int _replay = 0;

  /// 1.3 is the app-wide ceiling set in `app.dart`; there is no point offering
  /// a scale the app clamps away.
  double _scale = 1.0;
  bool _motion = true;

  /// Forced logical width, or null for the device's own. 390 is a phone,
  /// 1100 clears the 1024 tablet breakpoint in `SatLayout`.
  double? _forcedWidth;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final entry = widget.entry;
    final mq = MediaQuery.of(context);

    var data = mq.copyWith(
      textScaler: TextScaler.linear(_scale),
      disableAnimations: !_motion,
    );
    final forced = _forcedWidth;
    if (forced != null) {
      data = data.copyWith(size: Size(forced, mq.size.height));
    }

    Widget stage = KeyedSubtree(
      key: ValueKey(_replay),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.note != null) _BookNote(entry.note!),
          if (entry.states.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Sp.s4),
              child: Text(
                'No states — this widget is not rendered in the book.',
                style: SatType.sans(size: 13, color: sc.textDim),
              ),
            ),
          for (final s in entry.states) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.s4, Sp.s5, Sp.s4, Sp.s2),
              child: Text(
                s.label,
                style: SatType.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  color: sc.accentText,
                ),
              ),
            ),
            if (s.note != null) _BookNote(s.note!),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: Sp.s4),
              padding: const EdgeInsets.all(Sp.s3),
              decoration: SatBox.d(
                color: sc.bg1,
                borderRadius: SatR.a(12),
                border: SatB.all(color: sc.border0),
              ),
              child: Consumer(builder: (c, r, _) => s.build(c, r)),
            ),
          ],
          const SizedBox(height: Sp.s12),
        ],
      ),
    );

    stage = MediaQuery(
      data: data,
      child: SizedBox(width: forced, child: stage),
    );
    if (forced != null && forced > mq.size.width) {
      stage = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: stage,
      );
    }

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Column(
          children: [
            _BookBar(
              title: entry.name,
              subtitle: entry.group,
              onBack: () => Navigator.of(context).maybePop(),
              trailing: IconButton(
                tooltip: 'Replay entrance animations',
                icon: Icon(Icons.refresh_rounded, color: sc.textMd),
                onPressed: () => setState(() => _replay++),
              ),
            ),
            _axisStrip(context),
            Expanded(child: SingleChildScrollView(child: stage)),
          ],
        ),
      ),
    );
  }

  Widget _axisStrip(BuildContext context) {
    final sc = context.sat;
    final theme = ref.watch(satThemeProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s4,
        vertical: Sp.s2,
      ),
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border(bottom: BorderSide(color: sc.border0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Theme and skin are one decision in this app (ADR-0045/0047), so
            // they are one control. Selecting writes through to prefs — the
            // book borrows the real picker rather than faking a local one,
            // which would need SatShape's globals mutated behind the app's back.
            PopupMenuButton<SatTheme>(
              tooltip: 'Theme and skin',
              initialValue: theme,
              onSelected: (t) => ref.read(satThemeProvider.notifier).select(t),
              itemBuilder: (_) => [
                for (final t in SatTheme.values)
                  PopupMenuItem(value: t, child: Text(t.label)),
              ],
              child: _BookPill(
                label: theme.label,
                icon: Icons.palette_outlined,
                on: true,
              ),
            ),
            const SizedBox(width: Sp.s2),
            TextButton(
              onPressed: () =>
                  setState(() => _scale = _scale == 1.0 ? 1.3 : 1.0),
              child: _BookPill(
                label: _scale == 1.0 ? '1.0×' : '1.3×',
                icon: Icons.format_size_rounded,
                on: _scale != 1.0,
              ),
            ),
            const SizedBox(width: Sp.s2),
            TextButton(
              onPressed: () => setState(() => _motion = !_motion),
              child: _BookPill(
                label: _motion ? 'motion' : 'reduced',
                icon: Icons.animation_rounded,
                on: !_motion,
              ),
            ),
            const SizedBox(width: Sp.s2),
            TextButton(
              onPressed: () => setState(() {
                _forcedWidth = switch (_forcedWidth) {
                  null => _phoneWidth,
                  _phoneWidth => _tabletWidth,
                  _ => null,
                };
              }),
              child: _BookPill(
                label: switch (_forcedWidth) {
                  null => 'device',
                  _phoneWidth => 'phone',
                  _ => 'tablet',
                },
                icon: Icons.aspect_ratio_rounded,
                on: _forcedWidth != null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The book's own header. Deliberately not `SatAppBar` — book chrome next to a
/// widget under inspection would be one more thing to mistake for the widget.
class _BookBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  const _BookBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.s2, Sp.s2, Sp.s2, Sp.s2),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_rounded, color: sc.textMd),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SatType.sans(
                    size: 17,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
                Text(
                  subtitle,
                  style: SatType.mono(size: 11, color: sc.textDim),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _BookPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool on;
  const _BookPill({required this.label, required this.icon, required this.on});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final fg = on ? sc.accentText : sc.textMd;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s2h, vertical: Sp.s1),
      decoration: SatBox.d(
        color: on ? sc.accentSoft : sc.bg2,
        borderRadius: SatR.a(999),
        border: SatB.all(color: on ? sc.accentBorder : sc.border1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: Sp.s1),
          Text(label, style: SatType.mono(size: 11, color: fg)),
        ],
      ),
    );
  }
}

class _BookNote extends StatelessWidget {
  final String text;
  const _BookNote(this.text);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Sp.s4, Sp.s2, Sp.s4, 0),
      padding: const EdgeInsets.all(Sp.s2h),
      decoration: SatBox.d(
        color: sc.bg2,
        borderRadius: SatR.a(8),
        border: SatB.all(color: sc.border0),
      ),
      child: Text(
        text,
        style: SatType.sans(size: 12, height: 1.4, color: sc.textLo),
      ),
    );
  }
}

const double _phoneWidth = 390;
const double _tabletWidth = 1100;
